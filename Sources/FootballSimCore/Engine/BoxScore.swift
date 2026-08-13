import Foundation

/// Per-player lines from a played game. `02` §3.11, G-11.
///
/// The detailed engine produced no statistics at all: it recorded every duel and every ball handler
/// and nothing turned that into a line, so a played match had a scoreboard and no box score — while
/// the abstracted model, which resolves games nobody watches, had one.
///
/// **A pure function over a finished `GameRecord`.** It derives; it never re-resolves. That is what
/// makes it safe to call any number of times, and it is `03` §1.3's honesty invariant applied to
/// evidence: reading a game cannot change it.
public struct BoxScore: Sendable, Equatable {
    public let home: [PlayerGameStatistics]
    public let away: [PlayerGameStatistics]

    public init(home: [PlayerGameStatistics], away: [PlayerGameStatistics]) {
        self.home = home
        self.away = away
    }

    public var all: [PlayerGameStatistics] { home + away }

    /// Builds the box score for a finished game.
    public static func build(from game: GameRecord) -> BoxScore {
        var lines: [UUID: PlayerGameStatistics] = [:]
        var sides: [UUID: Side] = [:]

        func credit(_ id: UUID?, _ side: Side, _ line: (UUID) -> PlayerGameStatistics) {
            guard let id else { return }
            // A player's side is fixed by the first play they appear in. Nobody changes teams
            // mid-game, so a later disagreement would be an attribution bug rather than a transfer.
            if sides[id] == nil { sides[id] = side }
            let addition = line(id)
            lines[id] = lines[id].map { $0 + addition } ?? addition
        }

        for drive in game.drives {
            // The return, before the drive it started.
            if let kickoff = drive.startingKickoff, let returner = kickoff.returnerID {
                credit(returner, drive.offense) {
                    PlayerGameStatistics(
                        playerID: $0,
                        touchdowns: kickoff.returnTouchdown ? 1 : 0,
                        kickReturns: 1,
                        kickReturnYards: kickoff.returnYards
                    )
                }
            }

            for play in drive.plays {
                let offence = play.situation.possession
                let defence = offence.opponent
                let outcome = play.outcome
                let deciding = outcome.decidingMatchup

                switch outcome.result {
                case .gain, .touchdown, .fumbleLost:
                    if play.offensiveCall.playType == .pass {
                        credit(outcome.passerID, offence) {
                            PlayerGameStatistics(
                                playerID: $0, passAttempts: 1, completions: 1,
                                passingYards: outcome.yards,
                                passingTouchdowns: outcome.result == .touchdown ? 1 : 0
                            )
                        }
                        credit(outcome.targetID, offence) {
                            PlayerGameStatistics(
                                playerID: $0, targets: 1, receptions: 1,
                                receivingYards: outcome.yards,
                                touchdowns: outcome.result == .touchdown ? 1 : 0,
                                fumblesLost: outcome.result == .fumbleLost ? 1 : 0
                            )
                        }
                    } else {
                        credit(outcome.ballCarrierID, offence) {
                            PlayerGameStatistics(
                                playerID: $0, carries: 1, rushingYards: outcome.yards,
                                touchdowns: outcome.result == .touchdown ? 1 : 0,
                                fumblesLost: outcome.result == .fumbleLost ? 1 : 0
                            )
                        }
                    }
                    // The tackle goes to whoever won the duel that ended the play, which is exactly
                    // what `decidingMatchup` already answers for the match view.
                    if outcome.result != .touchdown {
                        credit(deciding?.defenderID, defence) {
                            PlayerGameStatistics(playerID: $0, tackles: 1)
                        }
                    }
                    if outcome.result == .fumbleLost {
                        credit(deciding?.defenderID, defence) {
                            PlayerGameStatistics(playerID: $0, forcedFumbles: 1)
                        }
                    }

                case .incompletion:
                    credit(outcome.passerID, offence) {
                        PlayerGameStatistics(playerID: $0, passAttempts: 1)
                    }
                    credit(outcome.targetID, offence) {
                        PlayerGameStatistics(playerID: $0, targets: 1)
                    }
                    credit(throwDefender(in: outcome), defence) {
                        PlayerGameStatistics(playerID: $0, passesDefended: 1)
                    }

                case .interception:
                    credit(outcome.passerID, offence) {
                        PlayerGameStatistics(playerID: $0, passAttempts: 1, interceptionsThrown: 1)
                    }
                    credit(outcome.targetID, offence) {
                        PlayerGameStatistics(playerID: $0, targets: 1)
                    }
                    credit(throwDefender(in: outcome), defence) {
                        PlayerGameStatistics(playerID: $0, interceptions: 1, passesDefended: 1)
                    }

                case .sack:
                    credit(outcome.passerID, offence) {
                        PlayerGameStatistics(playerID: $0, sacksTaken: 1)
                    }
                    credit(deciding?.defenderID, defence) {
                        PlayerGameStatistics(playerID: $0, tackles: 1, sacks: 1)
                    }

                case .fieldGoalGood, .fieldGoalMissed:
                    credit(outcome.ballCarrierID, offence) {
                        PlayerGameStatistics(
                            playerID: $0, fieldGoalsAttempted: 1,
                            fieldGoalsMade: outcome.result == .fieldGoalGood ? 1 : 0
                        )
                    }

                case .punt:
                    credit(outcome.ballCarrierID, offence) {
                        PlayerGameStatistics(playerID: $0, punts: 1, puntYards: outcome.yards)
                    }

                case .safety, .kneel, .penalty:
                    // A safety's tackle is already credited through the play that produced it; a
                    // kneel and a penalty produce no statistics by design, which is the same reason
                    // the calibration harness skips them.
                    break
                }
            }

            // The try. A kick is an extra point; a two-point attempt is deliberately not folded into
            // the passing and rushing counters, because a real box score keeps conversions apart
            // from scrimmage production and folding them in would inflate every quarterback's line.
            if let conversion = drive.conversion, conversion.choice == .kick {
                credit(conversion.outcome.ballCarrierID, drive.offense) {
                    PlayerGameStatistics(
                        playerID: $0, extraPointsAttempted: 1,
                        extraPointsMade: conversion.succeeded ? 1 : 0
                    )
                }
            }
        }

        let ordered = lines.values.sorted { $0.playerID.uuidString < $1.playerID.uuidString }
        return BoxScore(
            home: ordered.filter { sides[$0.playerID] == .home },
            away: ordered.filter { sides[$0.playerID] == .away }
        )
    }

    /// Turns a played game into the same `GameSummary` the abstracted path produces. `02` §3.14.
    ///
    /// The season records both kinds of game through one shape, so nothing downstream — standings,
    /// statistics, records, integrity, the archive — has to know or care which engine produced a
    /// result. A second summary shape for played games would be a second set of consumers to keep
    /// in step, and the first divergence would be silent.
    public static func summary(
        for game: GameRecord,
        homeParticipantIDs: [UUID],
        awayParticipantIDs: [UUID]
    ) -> GameSummary {
        let box = build(from: game)
        return GameSummary(
            homeScore: game.homeScore,
            awayScore: game.awayScore,
            homeStatistics: teamLine(for: .home, in: game, lines: box.home),
            awayStatistics: teamLine(for: .away, in: game, lines: box.away),
            homeParticipantIDs: homeParticipantIDs,
            awayParticipantIDs: awayParticipantIDs,
            playerStatistics: box.all.filter { !$0.isEmpty }
        )
    }

    /// One side's team line, summed from the plays it ran rather than from its box score.
    ///
    /// Yardage comes from the plays because a team's offensive yards include what its linemen did
    /// and its box score does not credit them — and penalty yardage is counted here and nowhere
    /// else, because `02` §3.5 keeps it out of offence.
    private static func teamLine(
        for side: Side,
        in game: GameRecord,
        lines: [PlayerGameStatistics]
    ) -> TeamGameStatistics {
        var passing = 0, rushing = 0, turnovers = 0, penalties = 0, penaltyYards = 0
        for drive in game.drives {
            for play in drive.plays {
                // Flags are counted against whoever committed them, which is **not** whoever had
                // the ball: half of them are defensive, and attributing every flag on a drive to the
                // offence would put a defensive holding on the offence's discipline record.
                if let flag = play.outcome.penalty, flag.against == side {
                    penalties += 1
                    if flag.accepted { penaltyYards += Swift.abs(flag.yards) }
                }
                guard drive.offense == side else { continue }
                switch play.outcome.result {
                case .interception, .fumbleLost:
                    turnovers += 1
                case .gain, .touchdown, .sack:
                    if play.offensiveCall.playType == .pass {
                        passing += play.outcome.yards
                    } else if play.offensiveCall.playType == .run {
                        rushing += play.outcome.yards
                    }
                case .incompletion, .fieldGoalGood, .fieldGoalMissed, .punt, .safety, .kneel,
                     .penalty:
                    break
                }
            }
        }
        let score = side == .home ? game.homeScore : game.awayScore
        return TeamGameStatistics(
            points: score,
            offensiveYards: passing + rushing,
            passingYards: passing,
            rushingYards: rushing,
            turnovers: turnovers,
            sacksAllowed: lines.reduce(0) { $0 + $1.sacksTaken },
            interceptionsThrown: lines.reduce(0) { $0 + $1.interceptionsThrown },
            penalties: penalties,
            penaltyYards: penaltyYards
        )
    }

    /// The defender the throw was contested by, which is the one the throwing matchup names.
    private static func throwDefender(in outcome: SnapOutcome) -> UUID? {
        outcome.matchups.first { $0.kind == .throwing }?.defenderID
            ?? outcome.matchups.first { $0.kind == .routeVersusCoverage }?.defenderID
    }
}
