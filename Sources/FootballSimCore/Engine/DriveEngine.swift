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

/// What the offence did with the try after a touchdown. `02` §3.4.
public enum ConversionChoice: String, Codable, Sendable, CaseIterable {
    case kick, twoPoint
}

/// The try after a touchdown.
///
/// **Recorded beside the drive rather than inside its play list.** A box score that counted
/// conversions as offensive snaps would corrupt every per-play rate `03` §5.1 calibrates — plays per
/// game, yards per play, completion rate — because a try is a scrimmage down that is not a scrimmage
/// play. `02` §3.4 states the rule; this field is where it is kept.
public struct ConversionRecord: Codable, Sendable, Equatable {
    public let choice: ConversionChoice
    public let succeeded: Bool
    /// 0, 1 or 2. Already included in the drive's `pointsScored`.
    public let points: Int
    /// The snap it resolved through, so the try has the same causal record every other play has.
    public let outcome: SnapOutcome

    public init(choice: ConversionChoice, succeeded: Bool, points: Int, outcome: SnapOutcome) {
        self.choice = choice
        self.succeeded = succeeded
        self.points = points
        self.outcome = outcome
    }
}

public struct DriveRecord: Codable, Sendable, Equatable {
    public let offense: Side
    public let plays: [PlayRecord]
    public let ending: DriveEnding
    public let pointsScored: Int
    public let startYardLine: Int
    /// Present exactly when the drive ended in a touchdown. `02` §3.4.
    public let conversion: ConversionRecord?
    /// The kickoff that handed this drive the ball, when one did. `02` §3.6.
    ///
    /// Attached to the drive that *received* rather than the one that scored, because it is what
    /// explains this drive's `startYardLine` — and because the opening kickoff belongs to no scoring
    /// drive at all. `DriveEngine` cannot fill it in: a kickoff needs both teams' personnel and the
    /// game's clock, so `GameEngine` owns it and attaches it here.
    public let startingKickoff: KickoffRecord?

    /// `conversion` and `startingKickoff` are defaulted so the existing constructions of a drive —
    /// every test fixture and the fingerprint's own mutation checks — keep meaning what they meant.
    public init(offense: Side, plays: [PlayRecord], ending: DriveEnding, pointsScored: Int,
                startYardLine: Int, conversion: ConversionRecord? = nil,
                startingKickoff: KickoffRecord? = nil) {
        self.offense = offense
        self.plays = plays
        self.ending = ending
        self.pointsScored = pointsScored
        self.startYardLine = startYardLine
        self.conversion = conversion
        self.startingKickoff = startingKickoff
    }

    // Decoding a record written before the conversion existed still works: the property is
    // optional, and synthesized decoding reads an optional with `decodeIfPresent`, so an absent
    // key is nil rather than a throw. No hand-written decoder is needed to get that, and one
    // written by hand here would be a second copy of the synthesized behaviour to keep in step.
}

/// Chooses the calls. P10 replaces this with real coordinator AI against a stated bar; P3 needs
/// *something* that calls plays so the loops can be tested, and says so.
///
/// ponytail: deliberately simple and deliberately named. A placeholder that pretended to be the
/// real thing is how a system ends up shipped hollow.
public protocol PlayCaller: Sendable {
    func offensiveCall(for situation: Situation, rules: any ClockRules.Type) -> OffensiveCall
    func defensiveCall(for situation: Situation, rules: any ClockRules.Type) -> DefensiveCall
    /// Kick the extra point, or go for two. `02` §3.4.
    ///
    /// - Parameter deficitAfterTouchdown: how far the scoring side trails **with the touchdown
    ///   already on the board**. Negative means they lead. The chart is written against this number
    ///   rather than against the pre-snap score, because that is the number a coach on the sideline
    ///   is actually looking at.
    func conversionChoice(
        deficitAfterTouchdown: Int,
        situation: Situation,
        rules: any ClockRules.Type
    ) -> ConversionChoice

    /// Whether this side stops the clock with a timeout. `02` §3.9.
    ///
    /// Asked of both sides after every snap that left the clock running, defence first, because the
    /// side that usually needs the clock stopped is the one without the ball.
    func callsTimeout(
        secondsRemainingInHalf: Int,
        trailing: Bool,
        isOffense: Bool,
        rules: any ClockRules.Type
    ) -> Bool
}

public extension PlayCaller {
    /// The chart, as the default. A caller only overrides this to be *worse* than arithmetic, which
    /// is a legitimate thing for a coordinator personality to be — but the default is the chart, so
    /// every existing conformance keeps compiling and none of them silently kicks forever.
    func conversionChoice(
        deficitAfterTouchdown: Int,
        situation: Situation,
        rules: any ClockRules.Type
    ) -> ConversionChoice {
        MatchupRules.twoPointIsIndicated(
            deficitAfterTouchdown: deficitAfterTouchdown,
            quarter: situation.quarter,
            quarters: rules.quarters
        ) ? .twoPoint : .kick
    }

    /// The clock-management rule as the default, for the same reason the conversion chart is one:
    /// every existing conformance keeps compiling, and none of them silently hoards its timeouts to
    /// the final whistle.
    func callsTimeout(
        secondsRemainingInHalf: Int,
        trailing: Bool,
        isOffense: Bool,
        rules: any ClockRules.Type
    ) -> Bool {
        guard trailing else { return false }
        return secondsRemainingInHalf <= (isOffense
            ? MatchupRules.offensiveTimeoutSecondsRemaining
            : MatchupRules.defensiveTimeoutSecondsRemaining)
    }
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

        // The first version threw on almost every snap and never threw deep: it ran only when
        // `distance <= 7`, and first-and-ten is ten. The calibration harness saw the consequence
        // immediately — six run plays per team-game against a band of 100 to 130 rush yards, and an
        // explosive-pass rate of zero, because every completion was exactly the mid-pass air
        // yardage. A caller with one play is not a baseline, it is a bug.
        //
        // Mixing is driven by the situation rather than by a coin, so the caller stays a pure
        // function of state and consumes no draws — the drive loop's snap seed is the only
        // randomness, which is what keeps a replay exact.
        // Mixed, not "always run on an early down". Running every first-and-ten put the harness at
        // 231 rush yards and 50 pass yards per team-game — a caller with one play again, just a
        // different one. The mix is a function of the situation so it stays pure and consumes no
        // draws; the drive loop's snap seed is the only randomness.
        let runsThisDown = (situation.yardLine + situation.down) % 2 == 0
        if !hurrying, runsThisDown, situation.down <= 2,
           situation.distance <= MatchupRules.runningDownDistance {
            return OffensiveCall(playType: .run,
                                 runGap: RunGap.allCases[situation.yardLine % RunGap.allCases.count],
                                 tempo: .normal)
        }
        let depth: PassDepth
        if hurrying, situation.distance >= MatchupRules.deepShotDistance {
            depth = .deep
        } else if situation.distance >= MatchupRules.deepShotDistance,
                  situation.down >= 3 || situation.yardLine % 4 == 0 {
            depth = .deep
        } else if situation.distance >= MatchupRules.longYardage {
            depth = .mid
        } else {
            depth = .short
        }
        return OffensiveCall(playType: .pass, passDepth: depth, tempo: hurrying ? .hurry : .normal)
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
        weather: Weather = .clear,
        driveSeed: UInt64,
        isAfterTurnover: Bool,
        clockRunning: Bool
    ) -> (drive: DriveRecord, next: Situation) {
        var situation = start
        var plays: [PlayRecord] = []
        var clockRunning = clockRunning
        var clockStoppedByFirstDown = false
        // Optional, not defaulted to `.endOfHalf`. It was, and since the loop's continue-guard
        // tested `ending == .endOfHalf`, the sentinel and a real terminal state were the same
        // value: every drive ended after exactly one play, and fieldGoal, punt, missedFieldGoal
        // and downs were endings the loop could never produce. The reachability test found it.
        var ending: DriveEnding?
        var points = 0
        var conversion: ConversionRecord?
        var afterTurnover = isAfterTurnover
        // Both sides are mutable through the drive because `02` §3.8's `forcedOut` is honoured
        // here: a player whose game ends is off the field for the *next* snap, not at the next
        // drive. Waiting for the drive boundary would leave a torn knee taking a dozen more snaps.
        var offense = offense
        var defense = defense

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
                weather: weather,
                rng: &rng
            )
            plays.append(PlayRecord(situation: situation, offensiveCall: offensiveCall,
                                    defensiveCall: defensiveCall, outcome: outcome,
                                    callInTriggers: triggers))

            // The player is off. Applied to both sides rather than to the one that "should" hold
            // them, because a snap involves twenty-two people and the record does not say which
            // shirt the injured one was wearing — `substituting` is a no-op on the side that does
            // not have them, which is cheaper than a lookup that could be wrong.
            if let injury = outcome.injury, injury.forcedOut {
                offense = offense.substituting(outPlayerID: injury.playerID)
                defense = defense.substituting(outPlayerID: injury.playerID)
            }

            // The drive loop is the clock authority. The pre-snap clock only runs if it was
            // running: after an incompletion, a score, or a first down under the college rule, the
            // offence gets to the line for free. `stopsClock` and `clockStopsOnFirstDown` were both
            // declared and read by nobody — the second is the one tier difference 03 section 2
            // names, and it was inert.
            // A stopped clock does not mean a free snap. The college first-down stop restarts on
            // the ready-for-play, so it costs a reduced charge rather than nothing — skipping the
            // whole pre-snap put college at 142 offensive plays per team-game against a band of 67
            // to 75, which is the clock model wrong in shape rather than a constant mistuned.
            let preSnap: Int
            if clockRunning {
                preSnap = offensiveCall.tempo.snapSeconds(rules: rules)
            } else if clockStoppedByFirstDown {
                preSnap = rules.readyForPlaySeconds
            } else {
                preSnap = 0
            }
            situation.secondsRemainingInQuarter -= preSnap + outcome.secondsElapsed
            // A penalty is not a first down however many yards it moved the ball, even when it
            // grants one: the clock rule this feeds is about the chains being reset by a *play*.
            // Without the guard, a fifteen-yard flag on first-and-ten would stop the college clock
            // as though the offence had run for it.
            let madeFirstDown = outcome.result != .penalty
                && outcome.yards >= situation.distance && !outcome.result.isTurnover
            let firstDownStop = rules.clockStopsOnFirstDown && madeFirstDown
                && situation.secondsRemainingInHalf(rules: rules)
                    > rules.firstDownStopEndsAtSecondsRemaining
            clockRunning = !outcome.result.stopsClock && !firstDownStop
            clockStoppedByFirstDown = firstDownStop

            // `02` §3.9. `Situation.timeoutsRemaining` was written at kickoff, reset at halftime and
            // decremented nowhere, so a timeout was a number on a scoreboard rather than a decision
            // — while `02` §3.2 sells it as one of the five things a coach may change mid-match.
            //
            // Both sides are asked, defence first: the side that usually needs the clock stopped is
            // the one without the ball, and asking the offence first would let it spend the timeout
            // the defence was about to.
            if clockRunning {
                let offenceSide = situation.possession
                for side in [offenceSide.opponent, offenceSide] {
                    guard let remaining = situation.timeoutsRemaining[side], remaining > 0 else {
                        continue
                    }
                    let margin = side == .home
                        ? situation.homeScore - situation.awayScore
                        : situation.awayScore - situation.homeScore
                    guard caller.callsTimeout(
                        secondsRemainingInHalf: situation.secondsRemainingInHalf(rules: rules),
                        trailing: margin < 0,
                        isOffense: side == offenceSide,
                        rules: rules
                    ) else { continue }
                    situation.timeoutsRemaining[side] = remaining - 1
                    clockRunning = false
                    break
                }
            }

            switch outcome.result {
            case .touchdown:
                ending = .touchdown
                // Six, and then the try — which can miss. It used to be six plus one, always, so
                // `02` §3.4's decision did not exist and the kick could not be missed by a kicker
                // who cannot kick.
                let resolved = resolveConversion(
                    after: situation, offense: offense, defense: defense, caller: caller,
                    rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: weather,
                    driveSeed: driveSeed
                )
                conversion = resolved
                points = MatchupRules.touchdownPoints + resolved.points
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
            case .penalty:
                // `02` §3.5. The down is replayed unless the flag carries an automatic first down,
                // so a penalty never advances it — the drive's play bound is what stops a
                // pathological run of them, the same bound that stops a resolver returning zero
                // yards forever.
                situation.yardLine = Swift.min(Swift.max(situation.yardLine + outcome.yards, 1), 99)
                if outcome.penalty?.automaticFirstDown == true {
                    situation.down = 1
                    situation.distance = Swift.min(MatchupRules.yardsForFirstDown,
                                                   100 - situation.yardLine)
                } else {
                    // Enforced against the chains, not against the down. Five yards to a defence
                    // flagged on third-and-three is a first down; five yards against an offence on
                    // first-and-ten is first-and-fifteen.
                    let remaining = situation.distance - outcome.yards
                    if remaining <= 0 {
                        situation.down = 1
                        situation.distance = Swift.min(MatchupRules.yardsForFirstDown,
                                                       100 - situation.yardLine)
                    } else {
                        situation.distance = Swift.min(remaining, 100 - situation.yardLine)
                    }
                }
                if situation.secondsRemainingInQuarter <= 0 {
                    ending = situation.quarter % 2 == 0 ? .endOfHalf : .endOfQuarter
                }
                if ending != nil { break }
                continue
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
                            pointsScored: Swift.abs(points), startYardLine: start.yardLine,
                            conversion: conversion),
                next)
    }

    /// Resolves the try after a touchdown. `02` §3.4.
    ///
    /// Draws from its own generator, derived from the drive under a reserved ordinal one past the
    /// last legal play index. That is what makes adding the try harmless to everything before it:
    /// no snap's stream moves, and a try that consumes a variable number of draws — the two-point
    /// snap can break tackles — cannot shift anything, because nothing reads this generator after it.
    ///
    /// - Parameter situation: the situation the touchdown was scored *from*, so the score it carries
    ///   does not yet include the six points.
    static func resolveConversion(
        after situation: Situation,
        offense: SnapPersonnel,
        defense: SnapPersonnel,
        caller: some PlayCaller,
        rules: any ClockRules.Type,
        homeFieldAdvantage: Double,
        weather: Weather = .clear,
        driveSeed: UInt64
    ) -> ConversionRecord {
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: driveSeed, scope: .snap, ordinal: MatchupRules.conversionSeedOrdinal
        ))
        // `scoreDifferential` is already from the scoring side's perspective, so the deficit with
        // the touchdown on the board is its negation plus the six points just scored.
        let deficitAfterTouchdown = -(situation.scoreDifferential + MatchupRules.touchdownPoints)
        let choice = caller.conversionChoice(
            deficitAfterTouchdown: deficitAfterTouchdown, situation: situation, rules: rules
        )
        let personnel = SnapPersonnel(offense: offense.offense, defense: defense.defense)

        var trySituation = situation
        trySituation.down = 1
        switch choice {
        case .kick:
            trySituation.yardLine = 100 - MatchupRules.extraPointKickYardsToGoal
            trySituation.distance = MatchupRules.extraPointKickYardsToGoal
            let outcome = SnapResolver.resolve(
                offensiveCall: OffensiveCall(playType: .fieldGoal),
                defensiveCall: caller.defensiveCall(for: trySituation, rules: rules),
                personnel: personnel, situation: trySituation, rules: rules,
                homeFieldAdvantage: homeFieldAdvantage, weather: weather, rng: &rng
            )
            let good = outcome.result == .fieldGoalGood
            return ConversionRecord(choice: .kick, succeeded: good,
                                    points: good ? MatchupRules.extraPointPoints : 0,
                                    outcome: outcome)
        case .twoPoint:
            trySituation.yardLine = 100 - MatchupRules.twoPointYardsToGoal
            trySituation.distance = MatchupRules.twoPointYardsToGoal
            var call = caller.offensiveCall(for: trySituation, rules: rules)
            // A try is a scrimmage down by definition. A caller that answers one with a punt, a
            // kick or a kneel is answering a question it was not asked — most callers branch on
            // fourth down and this is a first — so the call is replaced rather than obeyed.
            if call.playType != .run, call.playType != .pass {
                call.playType = .run
            }
            let outcome = SnapResolver.resolve(
                offensiveCall: call,
                defensiveCall: caller.defensiveCall(for: trySituation, rules: rules),
                personnel: personnel, situation: trySituation, rules: rules,
                homeFieldAdvantage: homeFieldAdvantage, weather: weather, rng: &rng
            )
            let good = outcome.result == .touchdown
            return ConversionRecord(choice: .twoPoint, succeeded: good,
                                    points: good ? MatchupRules.twoPointPoints : 0,
                                    outcome: outcome)
        }
    }
}
