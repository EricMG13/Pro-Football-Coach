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
        mix(homeScore); mix(awayScore); mix(drives.count)
        for drive in drives {
            mix(drive.pointsScored)
            mix(drive.startYardLine)
            mix(DriveEnding.allCases.firstIndex(of: drive.ending) ?? -1)
            for play in drive.plays {
                mix(SnapResult.allCases.firstIndex(of: play.outcome.result) ?? -1)
                mix(play.outcome.yards)
                mix(play.outcome.secondsElapsed)
                mix(play.situation.down)
                mix(play.situation.distance)
                mix(play.situation.yardLine)
                mix(play.outcome.matchups.count)
                for matchup in play.outcome.matchups {
                    mix(Int((matchup.leverage * 1_000_000).rounded()))
                }
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
        var rng = SeededRandom(seed: seed)
        let rules = tier.clockRules
        var situation = Situation(
            yardLine: MatchupRules.kickoffTouchbackYardLine,
            possession: .home,
            quarter: 1,
            secondsRemainingInQuarter: rules.quarterSeconds,
            timeoutsRemaining: [.home: rules.timeoutsPerHalf, .away: rules.timeoutsPerHalf]
        )
        var drives: [DriveRecord] = []

        for _ in 0..<MatchupRules.maximumDrivesPerGame {
            let offense = situation.possession == .home ? home : away
            let defense = situation.possession == .home ? away : home
            let (drive, next) = DriveEngine.run(
                from: situation, offense: offense, defense: defense, caller: caller, rules: rules,
                homeFieldAdvantage: homeFieldAdvantage, rng: &rng
            )
            drives.append(drive)
            situation = next

            // Roll the clock into the next quarter when this one runs out, and stop at the end of
            // regulation. Overtime is a tier rule and belongs to the phase that has standings to
            // care about a tie; P3 records the tie.
            while situation.secondsRemainingInQuarter <= 0,
                  situation.quarter < rules.quarters {
                situation.quarter += 1
                situation.secondsRemainingInQuarter += rules.quarterSeconds
                if situation.quarter == 3 {
                    situation.timeoutsRemaining = [.home: rules.timeoutsPerHalf,
                                                   .away: rules.timeoutsPerHalf]
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
