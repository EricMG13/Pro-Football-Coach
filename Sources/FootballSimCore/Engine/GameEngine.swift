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
        stage: CompetitionStage = .regularSeason,
        home: SnapPersonnel,
        away: SnapPersonnel,
        caller: some PlayCaller = BaselinePlayCaller(),
        homeFieldAdvantage: Double = MatchupRules.homeAdvantage,
        seed: UInt64,
        initialSituation: Situation? = nil
    ) -> GameRecord {
        MatchReducer.playToCompletion(
            tier: tier,
            stage: stage,
            home: home,
            away: away,
            caller: caller,
            homeFieldAdvantage: homeFieldAdvantage,
            seed: seed,
            initialSituation: initialSituation
        ).record
    }
}
