import Foundation

/// A finished game.
public struct GameRecord: Codable, Sendable, Equatable {
    public let homeScore: Int
    public let awayScore: Int
    public let drives: [DriveRecord]
    public let tier: Tier
    /// What it was played in. `02` §3.10. Defaulted so every existing construction of a record — the
    /// fingerprint's own mutation checks among them — keeps meaning what it meant.
    public let weather: Weather
    /// Every call-in the game raised, and what was answered. `02` §3.15. Empty when the game was
    /// played without a driver, which is every game in the world the coach does not control.
    public let callIns: [MatchCallInRecord]

    public init(homeScore: Int, awayScore: Int, drives: [DriveRecord], tier: Tier,
                weather: Weather = .clear, callIns: [MatchCallInRecord] = []) {
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.drives = drives
        self.tier = tier
        self.weather = weather
        self.callIns = callIns
    }

    public var winner: Side? {
        if homeScore > awayScore { return .home }
        if awayScore > homeScore { return .away }
        return nil
    }

    public var plays: [PlayRecord] { drives.flatMap(\.plays) }

    /// A fingerprint of the whole play-by-play, for the cross-process determinism assertion
    /// `03` §3 asks for: "same seed across two separate process invocations, compared by **hash of
    /// the full play-by-play**."
    ///
    /// Order-sensitive by construction, and built from the fields that would move if the engine
    /// drifted. FNV-1a rather than a sum, because a sum is blind to reordering, which is the whole
    /// thing this is for.
    public var playByPlayFingerprint: UInt64 {
        var value: UInt64 = 0xCBF2_9CE4_8422_2325
        func mix(_ number: Int) {
            withUnsafeBytes(of: Int64(number).littleEndian) { bytes in
                for byte in bytes { value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
            }
        }
        func mixBytes<T>(_ value_: T) {
            withUnsafeBytes(of: value_) { bytes in
                for byte in bytes { value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
            }
        }
        func index<T: CaseIterable & Equatable>(_ item: T) -> Int {
            (T.allCases as? [T])?.firstIndex(of: item) ?? -1
        }

        mix(homeScore); mix(awayScore); mix(drives.count); mix(index(tier))
        mix(index(weather))
        // The answers changed the game, so the gate has to see them: two runs that differ only in
        // what a coach said at a call-in are different games and must fingerprint differently.
        mix(callIns.count)
        for callIn in callIns {
            mix(callIn.driveIndex)
            mix(index(callIn.trigger))
            mix(index(callIn.chosen))
        }
        for drive in drives {
            mix(drive.pointsScored)
            mix(drive.startYardLine)
            mix(index(drive.ending))
            mix(index(drive.offense))
            for play in drive.plays {
                // Every field, not a chosen few. The first version mixed the result, the yardage,
                // the clock and three situation numbers — and was blind to possession, the quarter,
                // the score, both play calls, the call-in triggers, the matchup kinds and every
                // player identity. Seven separate mutations of a real game produced a byte-identical
                // fingerprint, including flipping possession on every drive. A determinism gate
                // that cannot see who had the ball is not a determinism gate.
                mix(index(play.outcome.result))
                mix(play.outcome.yards)
                mix(play.outcome.secondsElapsed)
                mix(play.situation.down)
                mix(play.situation.distance)
                mix(play.situation.yardLine)
                mix(index(play.situation.possession))
                mix(play.situation.quarter)
                mix(play.situation.secondsRemainingInQuarter)
                mix(play.situation.homeScore)
                mix(play.situation.awayScore)
                for side in Side.allCases { mix(play.situation.timeoutsRemaining[side] ?? -1) }
                mix(index(play.offensiveCall.playType))
                mix(index(play.offensiveCall.passDepth))
                mix(index(play.offensiveCall.runGap))
                mix(index(play.offensiveCall.tempo))
                mix(Int((play.offensiveCall.aggression * 1_000_000).rounded()))
                mix(index(play.defensiveCall.coverage))
                mix(play.defensiveCall.rushers)
                mix(Int((play.defensiveCall.aggression * 1_000_000).rounded()))
                mix(play.callInTriggers.count)
                for trigger in play.callInTriggers { mix(index(trigger)) }
                mixBytes(play.outcome.ballCarrierID?.uuid ?? UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0,
                                                                        0, 0, 0, 0, 0, 0, 0, 0)).uuid)
                mix(play.outcome.matchups.count)
                for matchup in play.outcome.matchups {
                    mix(index(matchup.kind))
                    mixBytes(matchup.attackerID.uuid)
                    mixBytes(matchup.defenderID.uuid)
                    mix(Int((matchup.leverage * 1_000_000).rounded()))
                }
            }
            // The conversion is not in `plays` by design (`02` §3.4), so it needs mixing here or
            // the determinism gate would be blind to a whole class of outcome — including the
            // difference between a kick and a two-point try, which is a coaching decision.
            if let conversion = drive.conversion {
                mix(index(conversion.choice))
                mix(conversion.points)
                mix(conversion.succeeded ? 1 : 0)
                mix(index(conversion.outcome.result))
                mix(conversion.outcome.yards)
            } else {
                mix(-1)
            }
            // Same reasoning as the conversion: a kickoff is not a play, so nothing above would see
            // an onside kick that changed hands or a return that scored.
            if let kickoff = drive.startingKickoff {
                mix(index(kickoff.type))
                mix(index(kickoff.kickingSide))
                mix(kickoff.recoveredByKickingTeam ? 1 : 0)
                mix(kickoff.touchback ? 1 : 0)
                mix(kickoff.returnYards)
                mix(kickoff.resultingYardLine)
                mix(kickoff.points)
            } else {
                mix(-2)
            }
        }
        return value
    }
}

/// The game loop.
public enum GameEngine {
    /// Plays a whole game, seeded.
    ///
    /// Bounded by `MatchupRules.maximumDrivesPerGame` for the same reason the drive loop is
    /// bounded: an unbounded loop is a hang rather than a bug.
    public static func play(
        tier: Tier,
        home: SnapPersonnel,
        away: SnapPersonnel,
        caller: some PlayCaller = BaselinePlayCaller(),
        homeFieldAdvantage: Double = MatchupRules.homeAdvantage,
        week: Int = 1,
        weather: Weather? = nil,
        callIns: CallInDriver? = nil,
        seed: UInt64
    ) -> GameRecord {
        let rules = tier.clockRules
        // Drawn from the game's own seed under the game scope when the caller does not state it, so
        // a replay plays the same weather and a scheduler that knows the venue can override it.
        var weatherRNG = SeededRandom(seed: SeededRandom.derive(from: seed, scope: .game,
                                                                ordinal: 2))
        let conditions = weather ?? Weather.draw(week: week, rng: &weatherRNG)
        var situation = Situation(
            yardLine: MatchupRules.kickoffTouchbackYardLine,
            possession: .home,
            quarter: 1,
            secondsRemainingInQuarter: rules.quarterSeconds,
            timeoutsRemaining: [.home: rules.timeoutsPerHalf, .away: rules.timeoutsPerHalf]
        )
        var drives: [DriveRecord] = []
        var afterTurnover = false
        var clockRunning = false
        var driver = callIns
        // `02` §3.8. A player forced out stays out: the drive loop replaces them for the rest of
        // that drive, and these carry the same substitutions into every drive after it. Without
        // this the injury would heal at the drive boundary, which is worse than not modelling it.
        var home = home
        var away = away

        // `02` §3.6. Every possession used to begin at a constant, so there was no return game, no
        // onside kick and no field-position variance anywhere in the sport this engine simulates.
        // The kickoff is resolved here rather than in the drive loop because it needs both teams'
        // personnel and sits *between* possessions, where neither side's `Situation` is authoritative.
        var pendingKickoff: KickoffRecord? = resolveKickoff(
            kickingSide: .away, home: home, away: away, caller: caller, rules: rules,
            homeFieldAdvantage: homeFieldAdvantage, weather: conditions, seed: seed, ordinal: 0,
            situation: &situation
        )

        for driveIndex in 0..<MatchupRules.maximumDrivesPerGame {
            let offense = situation.possession == .home ? home : away
            let defense = situation.possession == .home ? away : home
            // 03 section 3 clause 6's drive node. Deriving it per drive rather than threading one
            // generator through the whole game means a drive that ran long cannot shift the stream
            // the next drive reads.
            let driveSeed = SeededRandom.derive(from: seed, scope: .drive, ordinal: driveIndex)
            // `02` §3.15. The call-in is raised before the drive because that is the decision the
            // proposal models: every option it offers is a whole `TacticalPlan`, so what it asks is
            // what the offence does from here rather than which play runs next.
            let drive: DriveRecord
            let next: Situation
            if driver != nil {
                let plan = driver!.planForDrive(
                    index: driveIndex, situation: situation, isAfterTurnover: afterTurnover,
                    rules: rules
                )
                // Two branches rather than one, because the caller's type differs and the loop is
                // generic over it. The alternative — erasing to `any PlayCaller` — would put an
                // existential in the hot path of every snap of every game in the world.
                (drive, next) = DriveEngine.run(
                    from: situation, offense: offense, defense: defense,
                    caller: TacticalPlanCaller(offensivePlan: plan,
                                               defensivePlan: driver!.opponentPlan),
                    rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: conditions,
                    driveSeed: driveSeed, isAfterTurnover: afterTurnover, clockRunning: clockRunning
                )
            } else {
                (drive, next) = DriveEngine.run(
                    from: situation, offense: offense, defense: defense, caller: caller,
                    rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: conditions,
                    driveSeed: driveSeed, isAfterTurnover: afterTurnover, clockRunning: clockRunning
                )
            }
            drives.append(DriveRecord(
                offense: drive.offense, plays: drive.plays, ending: drive.ending,
                pointsScored: drive.pointsScored, startYardLine: drive.startYardLine,
                conversion: drive.conversion, startingKickoff: pendingKickoff
            ))
            pendingKickoff = nil
            situation = next
            // The same rule the drive loop just applied, applied to the copies that outlive it.
            // Replaying the drive's own plays rather than asking it what it did keeps `run`'s
            // signature and gives the identical answer: the choice is deterministic and the bench
            // is the same, so the sequence lands in the same place.
            home = home.substituting(forcedOutIn: drive.plays)
            away = away.substituting(forcedOutIn: drive.plays)

            // A score is followed by a kickoff, and a safety by a free kick from the side that gave
            // the points up — which is the same side in both cases, the one that was on offence.
            // `DriveEngine`'s epilogue has already flipped possession and spotted the touchback, so
            // this replaces that default rather than competing with it.
            if drive.ending == .touchdown || drive.ending == .fieldGoal || drive.ending == .safety {
                pendingKickoff = resolveKickoff(
                    kickingSide: drive.offense, home: home, away: away, caller: caller,
                    rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: conditions,
                    seed: seed, ordinal: driveIndex + 1, situation: &situation
                )
            }
            // 02 section 3.1's trigger, threaded across the drive boundary. It was a local of
            // DriveEngine.run that nothing ever set to true, so the trigger was declared and could
            // not fire — dead capability in the call-in system, which is the one system the
            // previous build failed hardest at.
            afterTurnover = drive.ending == .turnover || drive.ending == .downs
            clockRunning = drive.ending == .endOfQuarter

            // Roll the clock into the next quarter when this one runs out, and stop at the end of
            // regulation. Overtime is a tier rule and belongs to the phase that has standings to
            // care about a tie; P3 records the tie.
            while situation.secondsRemainingInQuarter <= 0,
                  situation.quarter < rules.quarters {
                situation.quarter += 1
                situation.secondsRemainingInQuarter += rules.quarterSeconds
                // Halftime: the ball changes hands and both sides get their timeouts back. The
                // quarter break between 1 and 2, or 3 and 4, changes neither.
                if situation.quarter == rules.quarters / 2 + 1 {
                    situation.timeoutsRemaining = [.home: rules.timeoutsPerHalf,
                                                   .away: rules.timeoutsPerHalf]
                    situation.possession = situation.possession.opponent
                    // The second half opens with a kickoff like the first, from whoever is not
                    // receiving. The manual flip above still decides who that is; this resolves the
                    // kick rather than assuming a touchback.
                    pendingKickoff = resolveKickoff(
                        kickingSide: situation.possession.opponent, home: home, away: away,
                        caller: caller, rules: rules, homeFieldAdvantage: homeFieldAdvantage,
                        weather: conditions, seed: seed,
                        ordinal: MatchupRules.maximumDrivesPerGame + 1, situation: &situation
                    )
                    clockRunning = false
                    afterTurnover = false
                }
            }
            if situation.quarter >= rules.quarters, situation.secondsRemainingInQuarter <= 0 {
                break
            }
        }

        // `02` §3.7. Regulation used to end the game whatever the score: the engine recorded the tie
        // and `ClockRules.overtime` — which has said `alternatingPossessions` for college and
        // `timedPeriod` for pro since P3 — was read by nothing.
        if situation.homeScore == situation.awayScore {
            playOvertime(home: home, away: away, caller: caller, rules: rules,
                         homeFieldAdvantage: homeFieldAdvantage, weather: conditions, seed: seed,
                         situation: &situation, drives: &drives)
        }

        return GameRecord(homeScore: situation.homeScore, awayScore: situation.awayScore,
                          drives: drives, tier: tier, weather: conditions,
                          callIns: driver?.raised ?? [])
    }

    /// Plays overtime in whichever format the tier declares. `02` §3.7.
    ///
    /// The two formats are genuinely different games and are written as two loops rather than one
    /// parameterised one: an alternating-possession overtime has no clock and guarantees both sides
    /// the ball, and a timed period has a clock and guarantees nothing. Folding them together would
    /// mean a flag inside every line of both.
    private static func playOvertime(
        home: SnapPersonnel,
        away: SnapPersonnel,
        caller: some PlayCaller,
        rules: any ClockRules.Type,
        homeFieldAdvantage: Double,
        weather: Weather,
        seed: UInt64,
        situation: inout Situation,
        drives: inout [DriveRecord]
    ) {
        // Mutable for the same reason regulation's are: `02` §3.8's forced-out player stays out,
        // and an overtime that put them back on the field would be the one part of the game where
        // an injury healed itself.
        var home = home
        var away = away
        // The toss. Deterministic like everything else — it comes from the game's own seed, so a
        // replay tosses the same way.
        var rng = SeededRandom(seed: SeededRandom.derive(from: seed, scope: .game, ordinal: 1))
        let firstPossession: Side = rng.chance(0.5) ? .home : .away
        // Past every ordinal regulation used: drives took 0..<maximum, the kickoffs took the
        // negatives, and the halftime kick took maximum + 1.
        var ordinal = MatchupRules.maximumDrivesPerGame + 2

        switch rules.overtime {
        case .alternatingPossessions:
            for period in 0..<MatchupRules.maximumOvertimePeriods {
                for side in [firstPossession, firstPossession.opponent] {
                    let start = Situation(
                        down: 1,
                        distance: Swift.min(MatchupRules.yardsForFirstDown,
                                            MatchupRules.overtimeYardsToGoal),
                        yardLine: 100 - MatchupRules.overtimeYardsToGoal,
                        possession: side,
                        homeScore: situation.homeScore,
                        awayScore: situation.awayScore,
                        quarter: rules.quarters + period + 1,
                        secondsRemainingInQuarter: MatchupRules.overtimeUntimedSeconds,
                        timeoutsRemaining: [.home: MatchupRules.overtimeTimeouts,
                                            .away: MatchupRules.overtimeTimeouts]
                    )
                    let (drive, next) = DriveEngine.run(
                        from: start,
                        offense: side == .home ? home : away,
                        defense: side == .home ? away : home,
                        caller: caller, rules: rules, homeFieldAdvantage: homeFieldAdvantage,
                        weather: weather,
                        driveSeed: SeededRandom.derive(from: seed, scope: .drive, ordinal: ordinal),
                        isAfterTurnover: false, clockRunning: false
                    )
                    ordinal += 1
                    drives.append(drive)
                    home = home.substituting(forcedOutIn: drive.plays)
                    away = away.substituting(forcedOutIn: drive.plays)
                    situation.homeScore = next.homeScore
                    situation.awayScore = next.awayScore
                    situation.quarter = start.quarter
                }
                // Both sides have had the ball, which is the rule that makes this format fair and
                // the reason the check sits outside the inner loop rather than inside it.
                if situation.homeScore != situation.awayScore { break }
            }

        case .timedPeriod:
            situation.quarter = rules.quarters + 1
            situation.secondsRemainingInQuarter = MatchupRules.overtimePeriodSeconds
            situation.timeoutsRemaining = [.home: MatchupRules.overtimeTimeouts,
                                           .away: MatchupRules.overtimeTimeouts]
            var pendingKickoff: KickoffRecord? = resolveKickoff(
                kickingSide: firstPossession.opponent, home: home, away: away, caller: caller,
                rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: weather, seed: seed,
                ordinal: ordinal, situation: &situation
            )
            ordinal += 1
            var afterTurnover = false
            var clockRunning = false

            for _ in 0..<MatchupRules.maximumOvertimeDrives {
                guard situation.secondsRemainingInQuarter > 0 else { break }
                let offense = situation.possession == .home ? home : away
                let defense = situation.possession == .home ? away : home
                let (drive, next) = DriveEngine.run(
                    from: situation, offense: offense, defense: defense, caller: caller,
                    rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: weather,
                    driveSeed: SeededRandom.derive(from: seed, scope: .drive, ordinal: ordinal),
                    isAfterTurnover: afterTurnover, clockRunning: clockRunning
                )
                ordinal += 1
                drives.append(DriveRecord(
                    offense: drive.offense, plays: drive.plays, ending: drive.ending,
                    pointsScored: drive.pointsScored, startYardLine: drive.startYardLine,
                    conversion: drive.conversion, startingKickoff: pendingKickoff
                ))
                pendingKickoff = nil
                situation = next
                home = home.substituting(forcedOutIn: drive.plays)
                away = away.substituting(forcedOutIn: drive.plays)
                if drive.ending == .touchdown || drive.ending == .fieldGoal
                    || drive.ending == .safety {
                    pendingKickoff = resolveKickoff(
                        kickingSide: drive.offense, home: home, away: away, caller: caller,
                        rules: rules, homeFieldAdvantage: homeFieldAdvantage, weather: weather,
                        seed: seed, ordinal: ordinal, situation: &situation
                    )
                    ordinal += 1
                }
                afterTurnover = drive.ending == .turnover || drive.ending == .downs
                clockRunning = false
            }
        }
    }

    /// Resolves one kickoff and moves the game to the receiving team's first-and-ten. `02` §3.6.
    ///
    /// Owns the whole transition — who kicks, who ends up with the ball, where, and what a return
    /// touchdown does to the score — because splitting those across the drive loop and this one is
    /// how a possession ends up flipped twice.
    private static func resolveKickoff(
        kickingSide: Side,
        home: SnapPersonnel,
        away: SnapPersonnel,
        caller: some PlayCaller,
        rules: any ClockRules.Type,
        homeFieldAdvantage: Double,
        weather: Weather,
        seed: UInt64,
        ordinal: Int,
        situation: inout Situation
    ) -> KickoffRecord {
        // Negative ordinals are the kickoff's reserved space inside the drive scope: `derive`
        // reinterprets the ordinal bit-for-bit rather than converting it, so -(n + 1) cannot
        // collide with drive n's own stream however many drives a game runs.
        let kickoffSeed = SeededRandom.derive(from: seed, scope: .drive, ordinal: -(ordinal + 1))
        var rng = SeededRandom(seed: kickoffSeed)
        let receivingSide = kickingSide.opponent
        let kicking = kickingSide == .home ? home : away
        let receiving = receivingSide == .home ? home : away
        let kickingScore = kickingSide == .home ? situation.homeScore : situation.awayScore
        let receivingScore = receivingSide == .home ? situation.homeScore : situation.awayScore

        let type = KickoffModel.chooseType(
            trailingBy: receivingScore - kickingScore,
            secondsRemainingInHalf: situation.secondsRemainingInHalf(rules: rules),
            quarter: situation.quarter,
            quarters: rules.quarters
        )
        var record = KickoffModel.resolve(type: type, kickingSide: kickingSide, kicking: kicking,
                                          receiving: receiving, weather: weather, rng: &rng)

        if record.returnTouchdown {
            // The try after a return touchdown goes through the same path every other touchdown's
            // does. The kickoff that follows is a touchback by rule rather than another return: a
            // chain of return touchdowns is an unbounded loop guarding a play that happens about
            // once a season, and `02` §3.6 states the bound rather than hiding it.
            var scoring = situation
            scoring.possession = receivingSide
            let conversion = DriveEngine.resolveConversion(
                after: scoring, offense: receiving, defense: kicking, caller: caller, rules: rules,
                homeFieldAdvantage: receivingSide == .home ? homeFieldAdvantage
                                                           : -homeFieldAdvantage,
                weather: weather,
                driveSeed: kickoffSeed
            )
            let points = MatchupRules.touchdownPoints + conversion.points
            if receivingSide == .home {
                situation.homeScore += points
            } else {
                situation.awayScore += points
            }
            record = KickoffRecord(
                type: record.type, kickingSide: kickingSide, touchback: record.touchback,
                returnYards: record.returnYards,
                resultingYardLine: MatchupRules.kickoffTouchbackYardLine,
                points: points, returnTouchdown: true,
                kickerID: record.kickerID, returnerID: record.returnerID
            )
            situation.possession = kickingSide
            situation.yardLine = MatchupRules.kickoffTouchbackYardLine
        } else {
            situation.possession = record.recoveredByKickingTeam ? kickingSide : receivingSide
            situation.yardLine = record.resultingYardLine
        }
        situation.down = 1
        situation.distance = Swift.min(MatchupRules.yardsForFirstDown, 100 - situation.yardLine)
        return record
    }
}
