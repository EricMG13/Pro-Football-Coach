import Foundation

/// One snap, with the situation it was resolved against. The unit a match view animates and a
/// box score is built from.
public struct PlayRecord: Codable, Sendable, Equatable {
    public let situation: Situation
    public let offensiveCall: OffensiveCall
    public let defensiveCall: DefensiveCall
    public let outcome: SnapOutcome
    /// Why the coach was pulled in on this snap, if they were. `02` §3.1.
    public let callInTriggers: [CallInTrigger]

    public init(
        situation: Situation,
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        outcome: SnapOutcome,
        callInTriggers: [CallInTrigger]
    ) {
        self.situation = situation
        self.offensiveCall = offensiveCall
        self.defensiveCall = defensiveCall
        self.outcome = outcome
        self.callInTriggers = callInTriggers
    }
}

/// How a drive ended.
public enum DriveEnding: String, Codable, Sendable, CaseIterable {
    case touchdown, fieldGoal, missedFieldGoal, punt, turnover, downs, safety
    /// The first or third quarter ran out mid-drive. **The teams change ends, not possession** —
    /// the first version treated every quarter boundary as the end of a half and handed the ball
    /// over, so possession changed at the end of Q1 and Q3 in every game.
    case endOfQuarter
    /// The half ran out. The ball does change hands, at the kickoff.
    ///
    /// There was an `endOfGame` case beside this one. It covers the same event — the fourth quarter
    /// running out is a half ending, and the game loop stops there — and nothing ever produced it,
    /// so it was a declared ending the engine could not reach.
    case endOfHalf

    /// Whether the ball changes hands. Read by the game loop rather than re-derived at each site.
    public var changesPossession: Bool {
        switch self {
        case .endOfQuarter: return false
        case .touchdown, .fieldGoal, .missedFieldGoal, .punt, .turnover, .downs, .safety,
             .endOfHalf:
            return true
        }
    }
}

public struct DriveRecord: Codable, Sendable, Equatable {
    public let offense: Side
    public let plays: [PlayRecord]
    public let ending: DriveEnding
    public let pointsScored: Int
    public let startYardLine: Int

    public init(offense: Side, plays: [PlayRecord], ending: DriveEnding, pointsScored: Int,
                startYardLine: Int) {
        self.offense = offense
        self.plays = plays
        self.ending = ending
        self.pointsScored = pointsScored
        self.startYardLine = startYardLine
    }
}

/// Chooses the calls. P10 replaces this with real coordinator AI against a stated bar; P3 needs
/// *something* that calls plays so the loops can be tested, and says so.
///
/// ponytail: deliberately simple and deliberately named. A placeholder that pretended to be the
/// real thing is how a system ends up shipped hollow.
public protocol PlayCaller: Sendable {
    func offensiveCall(for situation: Situation, rules: any ClockRules.Type) -> OffensiveCall
    func defensiveCall(for situation: Situation, rules: any ClockRules.Type) -> DefensiveCall
}

/// The stand-in caller for P3. Situationally sane, not good.
public struct BaselinePlayCaller: PlayCaller, Sendable {
    public init() {}

    public func offensiveCall(for situation: Situation, rules: any ClockRules.Type) -> OffensiveCall {
        if situation.isFourthDown {
            if situation.yardsToGoal <= MatchupRules.fieldGoalRangeYards {
                return OffensiveCall(playType: .fieldGoal)
            }
            if situation.distance <= MatchupRules.fourthDownGoForItDistance,
               situation.yardsToGoal <= MatchupRules.fourthDownGoForItTerritory {
                return OffensiveCall(playType: .run)
            }
            // Trailing late, punting is conceding. A caller that punted here would make
            // turnover-on-downs an ending the loop declares and never produces, and would also be
            // straightforwardly bad coaching — the reachability test caught both at once.
            if situation.scoreDifferential < 0, situation.isTwoMinute(rules: rules) {
                return OffensiveCall(playType: .pass, passDepth: .mid, tempo: .hurry, aggression: 1)
            }
            return OffensiveCall(playType: .punt)
        }
        let hurrying = situation.isTwoMinute(rules: rules) && situation.scoreDifferential <= 0
        let depth: PassDepth = situation.distance >= MatchupRules.longYardage ? .mid : .short
        // Run on early downs and short yardage, throw otherwise.
        if !hurrying, situation.down <= 2, situation.distance <= MatchupRules.longYardage {
            return OffensiveCall(playType: .run, tempo: hurrying ? .hurry : .normal)
        }
        return OffensiveCall(playType: .pass, passDepth: hurrying ? .mid : depth,
                             tempo: hurrying ? .hurry : .normal)
    }

    public func defensiveCall(for situation: Situation, rules: any ClockRules.Type) -> DefensiveCall {
        if situation.isTwoMinute(rules: rules), situation.scoreDifferential < 0 {
            return DefensiveCall(coverage: .prevent, rushers: MatchupRules.baseRushers)
        }
        if situation.isThirdAndLong {
            return DefensiveCall(coverage: .zoneDeep, rushers: MatchupRules.baseRushers + 1)
        }
        if situation.down <= 2, situation.distance <= MatchupRules.longYardage {
            return DefensiveCall(coverage: .man, rushers: MatchupRules.baseRushers)
        }
        return DefensiveCall(coverage: .zoneUnder, rushers: MatchupRules.baseRushers)
    }
}

/// The drive loop.
public enum DriveEngine {
    /// Runs one drive to its end.
    ///
    /// Bounded by `MatchupRules.maximumPlaysPerDrive`. An unbounded loop here is a hang rather than
    /// a bug — a resolver that returned zero yards forever would never reach a fourth down that
    /// ended anything — and `03` §7's budgets have no room for one.
    /// - Parameters:
    ///   - driveSeed: the drive's node in `03` §3 clause 6's hierarchy. Each snap derives its own
    ///     seed from it, which is what makes the variable draw count inside a snap harmless: a
    ///     snap that breaks three tackles cannot shift the stream the next snap reads.
    ///   - isAfterTurnover: whether the previous drive ended in one. `02` §3.1's trigger.
    public static func run(
        from start: Situation,
        offense: SnapPersonnel,
        defense: SnapPersonnel,
        caller: some PlayCaller,
        rules: any ClockRules.Type,
        homeFieldAdvantage: Double,
        driveSeed: UInt64,
        isAfterTurnover: Bool,
        clockRunning: Bool
    ) -> (drive: DriveRecord, next: Situation) {
        var situation = start
        var plays: [PlayRecord] = []
        var clockRunning = clockRunning
        // Optional, not defaulted to `.endOfHalf`. It was, and since the loop's continue-guard
        // tested `ending == .endOfHalf`, the sentinel and a real terminal state were the same
        // value: every drive ended after exactly one play, and fieldGoal, punt, missedFieldGoal
        // and downs were endings the loop could never produce. The reachability test found it.
        var ending: DriveEnding?
        var points = 0
        var afterTurnover = isAfterTurnover

        for playIndex in 0..<MatchupRules.maximumPlaysPerDrive {
            // 03 section 3 clause 6: league -> season -> week -> game -> drive -> snap. The
            // hierarchy used to stop at week; .game, .drive and .snap were declared scopes that
            // only the seed-derivation tests ever passed.
            var rng = SeededRandom(seed: SeededRandom.derive(from: driveSeed, scope: .snap,
                                                             ordinal: playIndex))
            let offensiveCall = caller.offensiveCall(for: situation, rules: rules)
            let defensiveCall = caller.defensiveCall(for: situation, rules: rules)
            let triggers = situation.situationalCallInTriggers(rules: rules,
                                                               isSnapAfterTurnover: afterTurnover)
            afterTurnover = false

            let outcome = SnapResolver.resolve(
                offensiveCall: offensiveCall, defensiveCall: defensiveCall,
                personnel: SnapPersonnel(offense: offense.offense, defense: defense.defense),
                situation: situation, rules: rules,
                homeFieldAdvantage: situation.possession == .home ? homeFieldAdvantage
                                                                  : -homeFieldAdvantage,
                rng: &rng
            )
            plays.append(PlayRecord(situation: situation, offensiveCall: offensiveCall,
                                    defensiveCall: defensiveCall, outcome: outcome,
                                    callInTriggers: triggers))

            // The drive loop is the clock authority. The pre-snap clock only runs if it was
            // running: after an incompletion, a score, or a first down under the college rule, the
            // offence gets to the line for free. `stopsClock` and `clockStopsOnFirstDown` were both
            // declared and read by nobody — the second is the one tier difference 03 section 2
            // names, and it was inert.
            let preSnap = clockRunning ? offensiveCall.tempo.snapSeconds(rules: rules) : 0
            situation.secondsRemainingInQuarter -= preSnap + outcome.secondsElapsed
            let madeFirstDown = outcome.yards >= situation.distance && !outcome.result.isTurnover
            let firstDownStop = rules.clockStopsOnFirstDown && madeFirstDown
                && situation.secondsRemainingInHalf(rules: rules)
                    > rules.firstDownStopEndsAtSecondsRemaining
            clockRunning = !outcome.result.stopsClock && !firstDownStop

            switch outcome.result {
            case .touchdown:
                ending = .touchdown
                points = MatchupRules.touchdownPoints + MatchupRules.extraPointPoints
            case .fieldGoalGood:
                ending = .fieldGoal
                points = MatchupRules.fieldGoalPoints
            case .fieldGoalMissed:
                ending = .missedFieldGoal
            case .punt:
                ending = .punt
            case .safety:
                ending = .safety
                points = -MatchupRules.safetyPoints
            case .interception, .fumbleLost:
                ending = .turnover
            case .gain, .sack, .incompletion, .kneel:
                // Advance the chains and try again.
                situation.yardLine = Swift.min(Swift.max(situation.yardLine + outcome.yards, 1), 99)
                if outcome.yards >= situation.distance {
                    situation.down = 1
                    situation.distance = Swift.min(MatchupRules.yardsForFirstDown,
                                                   100 - situation.yardLine)
                } else {
                    situation.distance -= outcome.yards
                    situation.down += 1
                    if situation.down > 4 { ending = .downs }
                }
                if situation.secondsRemainingInQuarter <= 0 {
                    // An odd quarter running out changes ends; an even one ends a half.
                    ending = situation.quarter % 2 == 0 ? .endOfHalf : .endOfQuarter
                }
                if ending != nil { break }
                continue
            }
            break
        }

        // Running out of plays without an ending is the bound firing, which is a half that ran
        // out rather than a drive that resolved.
        // Running out of plays without an ending is the bound firing.
        let finalEnding = ending ?? .endOfHalf

        var next = situation
        if finalEnding.changesPossession {
            next.possession = situation.possession.opponent
            // The new offence starts from the other end of the field.
            next.yardLine = Swift.min(Swift.max(100 - situation.yardLine, 1), 99)
            switch finalEnding {
            case .touchdown, .fieldGoal, .safety:
                next.yardLine = MatchupRules.kickoffTouchbackYardLine
            case .punt:
                let landed = situation.yardLine + (plays.last?.outcome.yards ?? 0)
                // A punt that reaches the goal line is a touchback, not a receiving team pinned on
                // its own 1. Two percent of measured punts were being clamped to the 1.
                next.yardLine = landed >= 100
                    ? MatchupRules.puntTouchbackYardLine
                    : Swift.min(Swift.max(100 - landed, 1), 99)
            default:
                break
            }
            next.down = 1
            next.distance = Swift.min(MatchupRules.yardsForFirstDown, 100 - next.yardLine)
        }
        if points > 0 {
            if situation.possession == .home { next.homeScore += points } else { next.awayScore += points }
        } else if points < 0 {
            // A safety scores for the defence.
            if situation.possession == .home { next.awayScore -= points } else { next.homeScore -= points }
        }

        return (DriveRecord(offense: start.possession, plays: plays, ending: finalEnding,
                            pointsScored: Swift.abs(points), startYardLine: start.yardLine),
                next)
    }
}
