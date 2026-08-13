import Foundation

/// A finished game.
public struct GameRecord: Codable, Sendable, Equatable {
    public let homeScore: Int
    public let awayScore: Int
    public let drives: [DriveRecord]
    public let tier: Tier

    public init(homeScore: Int, awayScore: Int, drives: [DriveRecord], tier: Tier) {
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.drives = drives
        self.tier = tier
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
        seed: UInt64
    ) -> GameRecord {
        let rules = tier.clockRules
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

        for driveIndex in 0..<MatchupRules.maximumDrivesPerGame {
            let offense = situation.possession == .home ? home : away
            let defense = situation.possession == .home ? away : home
            // 03 section 3 clause 6's drive node. Deriving it per drive rather than threading one
            // generator through the whole game means a drive that ran long cannot shift the stream
            // the next drive reads.
            let driveSeed = SeededRandom.derive(from: seed, scope: .drive, ordinal: driveIndex)
            let (drive, next) = DriveEngine.run(
                from: situation, offense: offense, defense: defense, caller: caller, rules: rules,
                homeFieldAdvantage: homeFieldAdvantage, driveSeed: driveSeed,
                isAfterTurnover: afterTurnover, clockRunning: clockRunning
            )
            drives.append(drive)
            situation = next
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
                    situation.yardLine = MatchupRules.kickoffTouchbackYardLine
                    situation.down = 1
                    situation.distance = MatchupRules.yardsForFirstDown
                    clockRunning = false
                    afterTurnover = false
                }
            }
            if situation.quarter >= rules.quarters, situation.secondsRemainingInQuarter <= 0 {
                break
            }
        }

        return GameRecord(homeScore: situation.homeScore, awayScore: situation.awayScore,
                          drives: drives, tier: tier)
    }
}
