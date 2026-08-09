import Foundation

/// Simulates one football game, play by play.
///
/// The same object serves every play mode: bulk season simming, the play-calling screen, and
/// the arcade mode (which overrides the outcome of the user's own snap and hands the result
/// back). Rules — clock, downs, scoring, overtime — live here and nowhere else, so no mode can
/// drift from any other.
public struct GameSimulator {

    /// How a possession ended, used to drive the next kickoff or change of possession.
    private enum DriveEnd {
        case touchdown, fieldGoal, punt, turnover, downs, safety, endOfHalf, endOfGame
    }

    public struct Options: Sendable {
        /// Keep the play-by-play. False for bulk simulation, which halves memory and time.
        public var retainPlays: Bool
        public var injuriesEnabled: Bool
        public var neutralSite: Bool

        public init(retainPlays: Bool = false, injuriesEnabled: Bool = true, neutralSite: Bool = false) {
            self.retainPlays = retainPlays
            self.injuriesEnabled = injuriesEnabled
            self.neutralSite = neutralSite
        }
    }

    // MARK: - State

    private let home: Team
    private let away: Team
    private var homeSnapshot: TeamSnapshot
    private var awaySnapshot: TeamSnapshot
    private let options: Options
    private let week: Int
    private let year: Int
    private let kind: GameKind
    private let scheduledGameID: UUID

    private var homeStats = TeamGameStats()
    private var awayStats = TeamGameStats()
    private var playerStats: [UUID: StatLine] = [:]
    private var plays: [PlayEvent] = []
    private var injuries: [InjuryOutcome] = []
    /// Players hurt during this game, so they stop being selected for later snaps.
    private var unavailable: Set<UUID> = []

    private var quarter = 1
    private var clock = LeagueRules.quarterLengthSeconds
    private var driveNumber = 0
    private var overtimePeriods = 0
    private var homeTimeouts = LeagueRules.timeoutsPerHalf
    private var awayTimeouts = LeagueRules.timeoutsPerHalf

    public init(
        home: Team,
        away: Team,
        week: Int,
        year: Int,
        kind: GameKind,
        scheduledGameID: UUID,
        options: Options = Options()
    ) {
        self.home = home
        self.away = away
        self.homeSnapshot = TeamSnapshot(team: home)
        self.awaySnapshot = TeamSnapshot(team: away)
        self.week = week
        self.year = year
        self.kind = kind
        self.scheduledGameID = scheduledGameID
        self.options = options
    }

    /// Convenience entry point: simulate a scheduled fixture from the league.
    public static func simulate(
        game: ScheduledGame,
        in league: League,
        rng: inout SeededRandom,
        retainPlays: Bool = false
    ) -> GameRecord? {
        guard let home = league.team(id: game.homeTeamID),
              let away = league.team(id: game.awayTeamID) else { return nil }
        var simulator = GameSimulator(
            home: home,
            away: away,
            week: game.week,
            year: league.year,
            kind: game.kind,
            scheduledGameID: game.id,
            options: Options(
                retainPlays: retainPlays,
                injuriesEnabled: league.settings.injuriesEnabled,
                neutralSite: game.isNeutralSite
            )
        )
        return simulator.run(rng: &rng)
    }

    // MARK: - Game loop

    /// Plays the whole game and returns the finished record.
    /// Where the game currently is. The nested loops that used to drive a game are hoisted into
    /// this so a caller can advance one snap at a time — which is what lets the arcade mode hand
    /// control to the player for their own offence without a second copy of the rules.
    private enum Stage {
        case notStarted, regulation, overtimeSetup, overtime, finished
    }

    private var stage: Stage = .notStarted
    private var offenseIsHome = false
    private var secondHalfReceiverIsHome = false
    private var nextYardLine = LeagueRules.touchbackYardLine
    private var situation = GameSituation()
    private var driveActive = false
    private var driveSnaps = 0
    private var overtimePossessions = 0

    /// The team on offence for the next snap.
    public var offenseTeamID: UUID { offenseIsHome ? home.id : away.id }

    /// Down, distance, clock and field position for the next snap.
    public var currentSituation: GameSituation { situation }

    public var isComplete: Bool { stage == .finished }

    /// False before the coin toss, so a caller can tell "waiting to start" from "user's ball".
    public var hasStarted: Bool { stage != .notStarted }

    /// The play-by-play so far. Empty unless `retainPlays` was set.
    public var playLog: [PlayEvent] { plays }

    /// Live score. Read from the running totals rather than the current situation, which is
    /// scoped to whoever has the ball and goes stale the moment possession changes.
    public var liveHomeScore: Int { homeStats.points }
    public var liveAwayScore: Int { awayStats.points }
    public var currentQuarter: Int { quarter }
    public var clockRemaining: Int { clock }

    /// Plays the whole game. Kept as a thin wrapper over `advance` so that a single code path
    /// serves bulk simulation and interactive play alike, and every existing test exercises the
    /// same machinery the arcade uses.
    public mutating func run(rng: inout SeededRandom) -> GameRecord {
        while advance(rng: &rng) {}
        return finish(rng: &rng)
    }

    /// Advances the game by one snap, or by one transition between drives, quarters or overtime
    /// periods. Returns false once the game is over.
    ///
    /// `userCall` and `execution` apply only to the very next snap, and only if that snap is a
    /// scrimmage play. Passing nothing gives exactly the simulated game.
    @discardableResult
    public mutating func advance(
        rng: inout SeededRandom,
        userCall: OffensivePlay? = nil,
        execution: PlayExecution = .neutral,
        defensiveRead: DefensiveInput? = nil
    ) -> Bool {
        switch stage {
        case .notStarted:
            performCoinToss(rng: &rng)
            return true

        case .regulation:
            if !driveActive { beginDrive() }
            if let outcome = takeSnap(
                userCall: userCall, execution: execution, defensiveRead: defensiveRead, rng: &rng
            ) {
                driveActive = false
                applyRegulationTransition(outcome, rng: &rng)
            }
            return stage != .finished

        case .overtimeSetup:
            beginOvertimePeriodIfNeeded(rng: &rng)
            return stage != .finished

        case .overtime:
            if !driveActive {
                // The inner loop of a period is bounded by its own clock.
                guard clock > 0 else {
                    stage = .overtimeSetup
                    return true
                }
                beginDrive()
            }
            if let outcome = takeSnap(
                userCall: userCall, execution: execution, defensiveRead: defensiveRead, rng: &rng
            ) {
                driveActive = false
                applyOvertimeTransition(outcome, rng: &rng)
            }
            return stage != .finished

        case .finished:
            return false
        }
    }

    /// Builds the finished record. Safe to call once the game is complete.
    public mutating func finish(rng: inout SeededRandom) -> GameRecord {
        creditAppearances()
        return GameRecord(
            id: rng.uuid(),
            scheduledGameID: scheduledGameID,
            week: week,
            year: year,
            kind: kind,
            homeTeamID: home.id,
            awayTeamID: away.id,
            homeStats: homeStats,
            awayStats: awayStats,
            playerStats: playerStats,
            plays: plays,
            injuries: injuries,
            overtimePeriods: overtimePeriods
        )
    }

    // MARK: - Stage transitions

    private mutating func performCoinToss(rng: inout SeededRandom) {
        // The winner receives, so the other side gets the second-half kickoff.
        offenseIsHome = rng.chance(0.5)
        secondHalfReceiverIsHome = !offenseIsHome
        nextYardLine = LeagueRules.touchbackYardLine
        recordPlay(
            offenseIsHome: offenseIsHome,
            category: .kickoff,
            yards: 0,
            situation: GameSituation(quarter: 1, clockSeconds: clock, yardLine: nextYardLine),
            description: "\(offenseIsHome ? home.abbreviation : away.abbreviation) receives the opening kickoff."
        )
        stage = .regulation
    }

    private mutating func applyRegulationTransition(_ outcome: DriveOutcome, rng: inout SeededRandom) {
        switch outcome.end {
        case .endOfGame:
            break
        case .endOfHalf:
            // Second half: whoever did not receive the opening kick gets the ball.
            offenseIsHome = secondHalfReceiverIsHome
            nextYardLine = LeagueRules.touchbackYardLine
        case .safety:
            // The team that conceded the safety kicks it back.
            nextYardLine = 40
        case .touchdown, .fieldGoal:
            offenseIsHome.toggle()
            nextYardLine = kickoffResult(rng: &rng)
        case .punt, .turnover, .downs:
            offenseIsHome.toggle()
            nextYardLine = outcome.nextYardLine
        }
        if quarter > 4 { stage = .overtimeSetup }
    }

    private mutating func beginOvertimePeriodIfNeeded(rng: inout SeededRandom) {
        // A decided game is over; a tied one only continues if the format allows another period.
        guard homeStats.points == awayStats.points else {
            stage = .finished
            return
        }
        guard kind.isPlayoff || overtimePeriods < LeagueRules.regularSeasonOvertimePeriods else {
            stage = .finished
            return
        }

        overtimePeriods += 1
        quarter = 4 + overtimePeriods
        clock = LeagueRules.overtimeLengthSeconds
        homeTimeouts = 2
        awayTimeouts = 2
        offenseIsHome = rng.chance(0.5)
        overtimePossessions = 0
        nextYardLine = LeagueRules.touchbackYardLine
        driveActive = false
        stage = .overtime
    }

    private mutating func applyOvertimeTransition(_ outcome: DriveOutcome, rng: inout SeededRandom) {
        overtimePossessions += 1

        // A touchdown ends it; otherwise both sides get a possession before a lead settles it.
        if outcome.end == .touchdown
            || (homeStats.points != awayStats.points && overtimePossessions >= 2)
            || outcome.end == .endOfHalf
            || outcome.end == .endOfGame {
            stage = .overtimeSetup
            return
        }

        offenseIsHome.toggle()
        switch outcome.end {
        case .punt, .turnover, .downs: nextYardLine = outcome.nextYardLine
        default: nextYardLine = kickoffResult(rng: &rng)
        }
    }

    /// Credits an appearance to everyone who dressed and stayed healthy. Linemen never record
    /// a counting stat, so without this their player cards would read zero games for a career.
    private mutating func creditAppearances() {
        for team in [home, away] {
            for player in team.activeRoster where player.isHealthy && !unavailable.contains(player.id) {
                recordPlayerStat(player.id) { $0.gamesPlayed += 1 }
            }
        }
    }

    // MARK: - Drives

    private struct DriveOutcome {
        let end: DriveEnd
        /// Where the opponent takes over, from their own perspective.
        let nextYardLine: Int
    }

    private mutating func beginDrive() {
        driveNumber += 1
        driveSnaps = 0
        driveActive = true
        situation = GameSituation(
            quarter: quarter,
            clockSeconds: clock,
            down: 1,
            distance: LeagueRules.firstDownYards,
            yardLine: nextYardLine,
            offenseScore: offenseIsHome ? homeStats.points : awayStats.points,
            defenseScore: offenseIsHome ? awayStats.points : homeStats.points,
            offenseTimeouts: offenseIsHome ? homeTimeouts : awayTimeouts,
            defenseTimeouts: offenseIsHome ? awayTimeouts : homeTimeouts,
            isOvertime: overtimePeriods > 0
        )
    }

    /// One iteration of a drive: handles an expired clock, then plays a snap. Returns a drive
    /// outcome when the possession ends, or nil to keep going.
    private mutating func takeSnap(
        userCall: OffensivePlay?,
        execution: PlayExecution,
        defensiveRead: DefensiveInput? = nil,
        rng: inout SeededRandom
    ) -> DriveOutcome? {
        // A drive cannot legally run forever; the bound is a safety net, not a rule.
        guard driveSnaps < 40 else {
            return DriveOutcome(end: .punt, nextYardLine: 100 - situation.yardLine)
        }
        driveSnaps += 1

        if clock <= 0 {
            let ended = advanceQuarter()
            if ended { return DriveOutcome(end: .endOfGame, nextYardLine: 25) }
            if quarter == 3 { return DriveOutcome(end: .endOfHalf, nextYardLine: 25) }
            if overtimePeriods > 0 { return DriveOutcome(end: .endOfHalf, nextYardLine: 25) }
            situation.quarter = quarter
        }
        situation.clockSeconds = clock
        situation.offenseScore = offenseIsHome ? homeStats.points : awayStats.points
        situation.defenseScore = offenseIsHome ? awayStats.points : homeStats.points

        // Copied through a local because `situation` is now stored on self, and passing it
        // inout to a mutating method would be overlapping access to the same value.
        var pending = situation
        let outcome = runPlay(
            offenseIsHome: offenseIsHome,
            situation: &pending,
            userCall: userCall,
            execution: execution,
            defensiveRead: defensiveRead,
            rng: &rng
        )
        situation = pending
        return outcome
    }

    /// Executes one snap. Returns a drive outcome when the possession ends.
    private mutating func runPlay(
        offenseIsHome: Bool,
        situation: inout GameSituation,
        userCall: OffensivePlay? = nil,
        execution: PlayExecution = .neutral,
        defensiveRead: DefensiveInput? = nil,
        rng: inout SeededRandom
    ) -> DriveOutcome? {
        let offense = offenseIsHome ? home : away
        let defense = offenseIsHome ? away : home

        let offensiveCoordinatorQuality = offense.staff(.offensiveCoordinator)?.playCallQuality ?? 0.7
        let defensiveCoordinatorQuality = defense.staff(.defensiveCoordinator)?.playCallQuality ?? 0.7


        // The AI call is drawn either way so the random stream is identical whether or not a
        // player is steering — a game must not diverge just because someone took the controls.
        let simulatedCall = PlayCaller.offensiveCall(
            situation: situation,
            team: offense,
            coordinatorQuality: offensiveCoordinatorQuality,
            rng: &rng
        )
        let call = userCall ?? simulatedCall
        let defensiveCall = PlayCaller.defensiveCall(
            situation: situation,
            team: defense,
            coordinatorQuality: defensiveCoordinatorQuality,
            rng: &rng
        )
        let tempo = PlayCaller.tempo(situation: situation)

        // A defensive read can only be scored once the offense's call is known — anticipating
        // a deep shot is worth nothing against a draw. It is resolved here, after the call is
        // drawn and before anything is rolled, and it replaces the execution rather than adding
        // to it: the two never coexist, because a read belongs to the side without the ball.
        var execution = execution
        if let defensiveRead, userCall == nil {
            execution = DefensiveInputs.execution(input: defensiveRead, against: call)
        }

        switch call {
        case .punt:
            return executePunt(offenseIsHome: offenseIsHome, situation: situation, rng: &rng)
        case .fieldGoal:
            return executeFieldGoal(
                offenseIsHome: offenseIsHome,
                situation: situation,
                execution: execution,
                rng: &rng
            )
        case .kneel:
            burnClock(seconds: 42)
            addTeamStats(offenseIsHome: offenseIsHome) { $0.plays += 1; $0.rushingYards -= 1 }
            // A kneel is a rushing attempt in the box score; attributing it keeps team
            // rushing yards equal to the sum of its players'.
            if let quarterback = availableStarter(team: offense, position: .qb) {
                recordPlayerStat(quarterback.id) { line in
                    line.carries += 1
                    line.rushingYards -= 1
                }
            }
            situation.down += 1
            situation.yardLine -= 1
            recordPlay(
                offenseIsHome: offenseIsHome,
                category: .kneel,
                yards: -1,
                situation: situation,
                description: "\(offense.abbreviation) takes a knee."
            )
            if situation.down > 4 {
                return DriveOutcome(end: .downs, nextYardLine: 100 - situation.yardLine)
            }
            return nil
        default:
            break
        }

        return executeScrimmagePlay(
            offenseIsHome: offenseIsHome,
            call: call,
            defensiveCall: defensiveCall,
            tempo: tempo,
            situation: &situation,
            execution: execution,
            rng: &rng
        )
    }

    // MARK: - Scrimmage plays

    private mutating func executeScrimmagePlay(
        offenseIsHome: Bool,
        call: OffensivePlay,
        defensiveCall: DefensivePlay,
        tempo: Tempo,
        situation: inout GameSituation,
        execution: PlayExecution = .neutral,
        rng: inout SeededRandom
    ) -> DriveOutcome? {
        let defense = offenseIsHome ? away : home

        let outcome: PlayResolver.Outcome
        if offenseIsHome {
            outcome = PlayResolver.resolve(
                call: call, defensiveCall: defensiveCall, tempo: tempo,
                offense: &homeSnapshot, defense: &awaySnapshot, situation: situation,
                homeFieldForOffense: !options.neutralSite, execution: execution, rng: &rng
            )
        } else {
            outcome = PlayResolver.resolve(
                call: call, defensiveCall: defensiveCall, tempo: tempo,
                offense: &awaySnapshot, defense: &homeSnapshot, situation: situation,
                homeFieldForOffense: false, execution: execution, rng: &rng
            )
        }

        addTeamStats(offenseIsHome: offenseIsHome) { stats in
            stats.plays += 1
            if situation.down == 3 { stats.thirdDownAttempts += 1 }
        }

        applyStats(outcome: outcome, offenseIsHome: offenseIsHome, call: call)
        if options.injuriesEnabled {
            rollInjury(offenseIsHome: offenseIsHome, outcome: outcome, rng: &rng)
        }

        burnClock(seconds: clockCost(for: outcome, call: call, tempo: tempo, situation: situation, rng: &rng))

        // Turnovers end the possession where the ball was taken.
        if outcome.isTurnover {
            let spot = min(max(situation.yardLine + outcome.yards, 1), 99)
            recordPlay(
                offenseIsHome: offenseIsHome,
                category: .turnover,
                yards: outcome.yards,
                situation: situation,
                description: outcome.description
            )
            addTeamStats(offenseIsHome: offenseIsHome) { $0.turnovers += 1 }
            return DriveOutcome(end: .turnover, nextYardLine: 100 - spot)
        }

        let newYardLine = situation.yardLine + outcome.yards

        // Touchdown.
        if newYardLine >= LeagueRules.fieldLengthYards {
            situation.yardLine = LeagueRules.fieldLengthYards
            score(offenseIsHome: offenseIsHome, points: LeagueRules.touchdownPoints)
            recordPlay(
                offenseIsHome: offenseIsHome,
                category: .touchdown,
                yards: outcome.yards,
                situation: situation,
                description: outcome.description + " Touchdown!"
            )
            attemptTry(
                offenseIsHome: offenseIsHome,
                situation: situation,
                execution: execution,
                rng: &rng
            )
            return DriveOutcome(end: .touchdown, nextYardLine: LeagueRules.touchbackYardLine)
        }

        // Safety: tackled in your own end zone.
        if newYardLine <= 0 {
            score(offenseIsHome: !offenseIsHome, points: LeagueRules.safetyPoints)
            situation.yardLine = 0
            recordPlay(
                offenseIsHome: offenseIsHome,
                category: .administrative,
                yards: outcome.yards,
                situation: situation,
                description: "Tackled in the end zone. Safety, \(defense.abbreviation)."
            )
            return DriveOutcome(end: .safety, nextYardLine: 40)
        }

        situation.yardLine = newYardLine
        recordPlay(
            offenseIsHome: offenseIsHome,
            category: outcome.category,
            yards: outcome.yards,
            situation: situation,
            description: outcome.description
        )

        // First down or next down.
        if outcome.yards >= situation.distance {
            addTeamStats(offenseIsHome: offenseIsHome) { stats in
                stats.firstDowns += 1
                if situation.down == 3 { stats.thirdDownConversions += 1 }
            }
            situation.down = 1
            situation.distance = min(LeagueRules.firstDownYards, situation.yardsToGoal)
        } else {
            situation.down += 1
            situation.distance -= outcome.yards
            if situation.down > 4 {
                return DriveOutcome(end: .downs, nextYardLine: 100 - situation.yardLine)
            }
        }
        return nil
    }

    // MARK: - Kicks

    private mutating func executeFieldGoal(
        offenseIsHome: Bool,
        situation: GameSituation,
        execution: PlayExecution = .neutral,
        rng: inout SeededRandom
    ) -> DriveOutcome {
        let offense = offenseIsHome ? home : away
        let distance = situation.fieldGoalDistance
        let kicker = availableStarter(team: offense, position: .k)
        let blocked = rng.chance(PlayMatrix.blockRate)
        let probability = min(
            0.995,
            max(0.01, PlayCaller.kickerFieldGoalProbability(team: offense, distance: distance)
                + execution.kickModifier)
        )
        let good = !blocked && rng.chance(probability)

        if let kicker {
            recordPlayerStat(kicker.id) { line in
                line.fieldGoalsAttempted += 1
                if good {
                    line.fieldGoalsMade += 1
                    line.longestFieldGoal = max(line.longestFieldGoal, distance)
                }
            }
        }
        burnClock(seconds: 6)
        addTeamStats(offenseIsHome: offenseIsHome) { $0.plays += 1 }

        if good {
            score(offenseIsHome: offenseIsHome, points: LeagueRules.fieldGoalPoints)
            recordPlay(
                offenseIsHome: offenseIsHome,
                category: .fieldGoal,
                yards: 0,
                situation: situation,
                description: "\(kicker?.name ?? "The kicker") connects from \(distance) yards.",
                involved: kicker.map { [$0.id] } ?? []
            )
            return DriveOutcome(end: .fieldGoal, nextYardLine: LeagueRules.touchbackYardLine)
        }

        recordPlay(
            offenseIsHome: offenseIsHome,
            category: .fieldGoal,
            yards: 0,
            situation: situation,
            description: blocked
                ? "The \(distance)-yard attempt is blocked."
                : "\(kicker?.name ?? "The kicker") misses from \(distance) yards.",
            involved: kicker.map { [$0.id] } ?? []
        )
        // A missed kick hands the ball over at the spot, never inside the 20.
        return DriveOutcome(end: .downs, nextYardLine: max(20, 100 - situation.yardLine))
    }

    private mutating func executePunt(
        offenseIsHome: Bool,
        situation: GameSituation,
        rng: inout SeededRandom
    ) -> DriveOutcome {
        let offense = offenseIsHome ? home : away
        let punter = availableStarter(team: offense, position: .p)
        let legStrength = punter.map { Double($0.ratings[.puntPower] - 70) * 0.18 } ?? -4
        let distance = Int(
            rng.gaussian(
                mean: PlayMatrix.puntMeanYards + legStrength,
                sd: PlayMatrix.puntSDYards
            ).rounded()
        )
        let landing = situation.yardLine + max(25, distance)

        burnClock(seconds: 12)
        addTeamStats(offenseIsHome: offenseIsHome) { $0.plays += 1 }

        if let punter {
            recordPlayerStat(punter.id) { line in
                line.punts += 1
                line.puntYards += max(25, distance)
            }
        }

        // Touchback, or a return from wherever it came down.
        var opponentStart: Int
        if landing >= 92 {
            opponentStart = LeagueRules.touchbackYardLine
        } else {
            let returnYards = rng.chance(0.62)
                ? Int(rng.gaussian(mean: PlayMatrix.puntReturnMeanYards, sd: 6).rounded())
                : 0
            opponentStart = min(max((100 - landing) + max(0, returnYards), 1), 99)
        }

        recordPlay(
            offenseIsHome: offenseIsHome,
            category: .punt,
            yards: 0,
            situation: situation,
            description: "\(punter?.name ?? "The punter") punts \(max(25, distance)) yards.",
            involved: punter.map { [$0.id] } ?? []
        )
        return DriveOutcome(end: .punt, nextYardLine: opponentStart)
    }

    /// Extra point or two-point try. Kept simple: the AI goes for two only when the maths says so.
    private mutating func attemptTry(
        offenseIsHome: Bool,
        situation: GameSituation,
        execution: PlayExecution = .neutral,
        rng: inout SeededRandom
    ) {
        let offense = offenseIsHome ? home : away
        let deficit = situation.defenseScore - situation.offenseScore
        // Chasing by 2, 5 or 10 after the touchdown is the classic go-for-two case.
        let goForTwo = situation.quarter >= 4
            && [2, 5, 10].contains(deficit + LeagueRules.touchdownPoints)

        if goForTwo {
            let converted = rng.chance(0.48)
            if converted { score(offenseIsHome: offenseIsHome, points: LeagueRules.twoPointConversionPoints) }
            recordPlay(
                offenseIsHome: offenseIsHome,
                category: .twoPointConversion,
                yards: 0,
                situation: situation,
                description: converted ? "The two-point try is good." : "The two-point try fails."
            )
            return
        }

        let kicker = availableStarter(team: offense, position: .k)
        let probability = kicker.map {
            min(0.995, 0.94 + Double($0.ratings[.kickAccuracy] - 70) * 0.0015 + execution.kickModifier)
        } ?? 0.90
        let good = !rng.chance(PlayMatrix.blockRate) && rng.chance(probability)
        if let kicker {
            recordPlayerStat(kicker.id) { line in
                line.extraPointsAttempted += 1
                if good { line.extraPointsMade += 1 }
            }
        }
        if good { score(offenseIsHome: offenseIsHome, points: LeagueRules.extraPointPoints) }
        recordPlay(
            offenseIsHome: offenseIsHome,
            category: .extraPoint,
            yards: 0,
            situation: situation,
            description: good ? "The extra point is good." : "The extra point is no good.",
            involved: kicker.map { [$0.id] } ?? []
        )
    }

    private mutating func kickoffResult(rng: inout SeededRandom) -> Int {
        if rng.chance(0.68) { return LeagueRules.touchbackYardLine }
        let start = Int(rng.gaussian(mean: 26, sd: 8).rounded())
        return min(max(start, 5), 98)
    }

    // MARK: - Clock, scoring, quarters

    private func clockCost(
        for outcome: PlayResolver.Outcome,
        call: OffensivePlay,
        tempo: Tempo,
        situation: GameSituation,
        rng: inout SeededRandom
    ) -> Int {
        // An incompletion or a play ending out of bounds stops the clock, so only the snap
        // interval burns; everything else runs the play clock too.
        let snapTime = rng.int(in: 4...8)
        if outcome.category == .pass && !outcome.completed { return snapTime }
        if outcome.isTurnover { return snapTime + 4 }
        let stoppage = rng.chance(0.18)
        return stoppage ? snapTime + 6 : snapTime + tempo.playClockSeconds
    }

    private mutating func burnClock(seconds: Int) {
        clock = max(0, clock - seconds)
    }

    /// Moves to the next quarter. Returns true when regulation is over.
    private mutating func advanceQuarter() -> Bool {
        quarter += 1
        if quarter > 4 { return true }
        clock = LeagueRules.quarterLengthSeconds
        if quarter == 3 {
            homeTimeouts = LeagueRules.timeoutsPerHalf
            awayTimeouts = LeagueRules.timeoutsPerHalf
        }
        return false
    }

    private mutating func score(offenseIsHome: Bool, points: Int) {
        let quarterIndex = min(max(quarter - 1, 0), 3)
        if offenseIsHome {
            homeStats.points += points
            homeStats.quarterPoints[quarterIndex] += points
        } else {
            awayStats.points += points
            awayStats.quarterPoints[quarterIndex] += points
        }
    }

    // MARK: - Stat plumbing

    private mutating func addTeamStats(offenseIsHome: Bool, _ mutate: (inout TeamGameStats) -> Void) {
        if offenseIsHome { mutate(&homeStats) } else { mutate(&awayStats) }
    }

    private mutating func recordPlayerStat(_ id: UUID, _ mutate: (inout StatLine) -> Void) {
        var line = playerStats[id] ?? StatLine()
        mutate(&line)
        playerStats[id] = line
    }

    private mutating func applyStats(
        outcome: PlayResolver.Outcome,
        offenseIsHome: Bool,
        call: OffensivePlay
    ) {
        addTeamStats(offenseIsHome: offenseIsHome) { stats in
            switch outcome.yardageKind {
            case .pass: stats.passingYards += outcome.completed ? outcome.yards : 0
            case .sack: stats.passingYards += outcome.yards
            case .run: stats.rushingYards += outcome.yards
            default: break
            }
        }
        if outcome.category == .sack {
            addTeamStats(offenseIsHome: !offenseIsHome) { $0.sacks += 1 }
        }

        for (playerID, line) in outcome.statDeltas {
            recordPlayerStat(playerID) { $0.add(line) }
        }
    }

    private mutating func rollInjury(
        offenseIsHome: Bool,
        outcome: PlayResolver.Outcome,
        rng: inout SeededRandom
    ) {
        // Roughly two and a half significant injuries per team per season.
        guard rng.chance(0.0022) else { return }
        let candidates = outcome.statDeltas.keys.sorted { $0.uuidString < $1.uuidString }
        guard let victimID = candidates.first(where: { !unavailable.contains($0) }) else { return }
        guard let (player, teamID) = locate(playerID: victimID) else { return }

        var severity = rng.double01()
        if player.has(.injuryProne) { severity += 0.18 }
        if player.has(.ironMan) { severity -= 0.22 }
        if player.age >= 31 { severity += 0.08 }

        let weeks: Int
        switch severity {
        case ..<0.55: weeks = rng.int(in: 1...2)
        case ..<0.85: weeks = rng.int(in: 3...6)
        case ..<0.96: weeks = rng.int(in: 8...11)
        default: weeks = 17
        }

        unavailable.insert(victimID)
        if teamID == home.id { homeSnapshot.markUnavailable(victimID) }
        else { awaySnapshot.markUnavailable(victimID) }
        injuries.append(
            InjuryOutcome(
                playerID: victimID,
                teamID: teamID,
                weeksOut: weeks,
                description: "\(player.name) (\(player.position.abbreviation)) leaves the game — out \(weeks) week\(weeks == 1 ? "" : "s")."
            )
        )
    }

    private func locate(playerID: UUID) -> (Player, UUID)? {
        if let player = home.player(id: playerID) { return (player, home.id) }
        if let player = away.player(id: playerID) { return (player, away.id) }
        return nil
    }

    private func availableStarter(team: Team, position: Position) -> Player? {
        team.depthOrder(for: position).first { !unavailable.contains($0.id) }
            ?? team.depthOrder(for: position).first
    }

    private mutating func recordPlay(
        offenseIsHome: Bool,
        category: PlayCategory,
        yards: Int,
        situation: GameSituation,
        description: String,
        involved: [UUID] = []
    ) {
        guard options.retainPlays else { return }
        plays.append(
            PlayEvent(
                id: UUID(),
                drive: driveNumber,
                quarter: quarter,
                clockSeconds: clock,
                offenseTeamID: offenseIsHome ? home.id : away.id,
                category: category,
                yards: yards,
                down: situation.down,
                distance: situation.distance,
                yardLine: situation.yardLine,
                description: description,
                involvedPlayerIDs: involved,
                homeScore: homeStats.points,
                awayScore: awayStats.points
            )
        )
    }
}
