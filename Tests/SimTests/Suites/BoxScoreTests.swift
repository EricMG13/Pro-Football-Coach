import Foundation
import FootballSimCore

func runBoxScoreTests() {
    suite("The box score") {
        test("defenders have a record at all") {
            // The gap this whole slice exists to close: the vocabulary was three offensive yardage
            // counters and a touchdown count, so every defender in the world accumulated nothing
            // across a twenty-season save.
            var state = GameState.bootstrap(seed: 86_001)
            var withTackles = 0, withSacks = 0, withInterceptions = 0
            for game in state.competition.currentSchedule.games.prefix(24) {
                let summary = AbstractGameSimulator.play(game, in: state)
                for line in summary.playerStatistics {
                    if line.tackles > 0 { withTackles += 1 }
                    if line.sacks > 0 { withSacks += 1 }
                    if line.interceptions > 0 { withInterceptions += 1 }
                }
            }
            _ = state
            expect(withTackles > 0, "no player made a tackle in 24 games")
            expect(withSacks > 0, "no player recorded a sack in 24 games")
            expect(withInterceptions > 0, "no player recorded an interception in 24 games")
        }

        test("the team line and the player lines agree") {
            // 02 section 3.11: a defence's sacks are the offence's sacks taken, exactly. The two are
            // derived from one number rather than from two plausible ones.
            let state = GameState.bootstrap(seed: 86_002)
            for game in state.competition.currentSchedule.games.prefix(16) {
                let summary = AbstractGameSimulator.play(game, in: state)
                let homeSet = Set(summary.homeParticipantIDs)
                let homeLines = summary.playerStatistics.filter { homeSet.contains($0.playerID) }
                let awayLines = summary.playerStatistics.filter { !homeSet.contains($0.playerID) }

                expectEqual(homeLines.reduce(0) { $0 + $1.sacks },
                            summary.awayStatistics.sacksAllowed,
                            "the home defence's sacks and the away offence's sacks taken disagree")
                expectEqual(awayLines.reduce(0) { $0 + $1.sacks },
                            summary.homeStatistics.sacksAllowed,
                            "the away defence's sacks and the home offence's sacks taken disagree")
                expectEqual(homeLines.reduce(0) { $0 + $1.interceptions },
                            summary.awayStatistics.interceptionsThrown,
                            "takeaways and giveaways disagree")
                expectEqual(homeLines.reduce(0) { $0 + $1.passingYards },
                            summary.homeStatistics.passingYards,
                            "the passing yards on the lines are not the team's passing yards")
                expectEqual(homeLines.reduce(0) { $0 + $1.rushingYards },
                            summary.homeStatistics.rushingYards,
                            "the rushing yards on the lines are not the team's rushing yards")
            }
        }

        test("every rate statistic is computable") {
            // The point of counting attempts. Before this, completion percentage could not be
            // computed anywhere in the game because nothing counted a pass.
            let state = GameState.bootstrap(seed: 86_003)
            var attempts = 0
            for game in state.competition.currentSchedule.games.prefix(16) {
                for line in AbstractGameSimulator.play(game, in: state).playerStatistics {
                    expect(line.completions <= line.passAttempts,
                           "a passer completed more than they attempted")
                    expect(line.receptions <= line.targets,
                           "a receiver caught more than they were thrown")
                    expect(line.fieldGoalsMade <= line.fieldGoalsAttempted,
                           "a kicker made more than they attempted")
                    expect(line.extraPointsMade <= line.extraPointsAttempted,
                           "a kicker made more tries than they took")
                    attempts += line.passAttempts
                }
            }
            expect(attempts > 0, "nobody attempted a pass in 16 games")
        }

        test("a line writes only what happened") {
            // FSC-003 is a release blocker about save size, so widening a per-player-per-game record
            // from four counters to twenty-six without sparse encoding would have made it worse.
            let id = UUID(uuidString: "00000000-0000-4000-C000-000000000001")!
            let empty = PlayerGameStatistics(playerID: id)
            let encoded = try JSONEncoder.stable().encode(empty)
            let object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            expectEqual(object.keys.count, 1,
                        "an empty line wrote \(object.keys.count) keys instead of its identifier")
            expect(empty.isEmpty, "an empty line does not know it is empty")

            let busy = PlayerGameStatistics(playerID: id, tackles: 7, sacks: 2)
            let busyObject = try JSONSerialization.jsonObject(
                with: try JSONEncoder.stable().encode(busy)
            ) as! [String: Any]
            expectEqual(busyObject.keys.count, 3, "a two-counter line wrote extra keys")
            expectEqual(try JSONDecoder().decode(PlayerGameStatistics.self,
                                                 from: try JSONEncoder.stable().encode(busy)),
                        busy, "a line did not survive its own encoding")
        }

        test("a season record written before the vocabulary widened still reads") {
            // The migration, done in place. GameState requires an exact schema match with no
            // migration path, so a version bump would reject every existing save outright.
            let id = UUID(uuidString: "00000000-0000-4000-C000-000000000002")!
            let legacy: [String: Any] = [
                "playerID": id.uuidString,
                "games": 9,
                "passingYards": 2_400,
                "rushingYards": 130,
                "receivingYards": 0,
                "touchdowns": 18,
            ]
            let data = try JSONSerialization.data(withJSONObject: legacy)
            let decoded = try JSONDecoder().decode(PlayerSeasonStatistics.self, from: data)
            expectEqual(decoded.games, 9)
            expectEqual(decoded.passingYards, 2_400)
            expectEqual(decoded.rushingYards, 130)
            expectEqual(decoded.touchdowns, 18)
            expectEqual(decoded.tackles, 0, "a legacy record invented a defensive statistic")
        }

        test("a played game produces per-player lines") {
            // G-11. The detailed engine recorded every duel and every ball handler and nothing
            // turned it into a line, so a played match had a scoreboard and no box score — while the
            // abstracted model, which resolves the games nobody watches, had one.
            let home = testPersonnel(offenseSkill: 74, defenseSkill: 72)
            let away = testPersonnel(offenseSkill: 70, defenseSkill: 71)
            let game = GameEngine.play(tier: .pro, home: home, away: away, seed: 4_711)
            let box = BoxScore.build(from: game)

            expect(!box.home.isEmpty && !box.away.isEmpty, "a side produced no lines at all")
            expect(box.all.contains { $0.tackles > 0 }, "nobody made a tackle")
            expect(box.all.contains { $0.passAttempts > 0 }, "nobody attempted a pass")
            expect(box.all.contains { $0.carries > 0 }, "nobody carried the ball")
            for line in box.all {
                expect(line.completions <= line.passAttempts,
                       "a passer completed more than they attempted")
                expect(line.receptions <= line.targets,
                       "a receiver caught more than they were thrown")
            }
        }

        test("the lines add up to the plays they came from") {
            let home = testPersonnel(offenseSkill: 74, defenseSkill: 72)
            let away = testPersonnel(offenseSkill: 70, defenseSkill: 71)
            for seed in UInt64(1)...12 {
                let game = GameEngine.play(tier: .college, home: home, away: away, seed: seed)
                let box = BoxScore.build(from: game)
                for side in [box.home, box.away] {
                    expectEqual(side.reduce(0) { $0 + $1.passingYards },
                                side.reduce(0) { $0 + $1.receivingYards },
                                "seed \(seed): passing yards and receiving yards disagree")
                    expectEqual(side.reduce(0) { $0 + $1.completions },
                                side.reduce(0) { $0 + $1.receptions },
                                "seed \(seed): completions and receptions disagree")
                }
                let sacks = box.all.reduce(0) { $0 + $1.sacks }
                let taken = box.all.reduce(0) { $0 + $1.sacksTaken }
                expectEqual(sacks, taken, "seed \(seed): sacks made and sacks taken disagree")
                let thrown = box.all.reduce(0) { $0 + $1.interceptionsThrown }
                let caught = box.all.reduce(0) { $0 + $1.interceptions }
                expectEqual(thrown, caught, "seed \(seed): interceptions thrown and caught disagree")
                expectEqual(box.all.reduce(0) { $0 + $1.sacks },
                            game.plays.filter { $0.outcome.result == .sack }.count,
                            "seed \(seed): the sacks on the lines are not the sacks in the game")
            }
        }

        test("reading a game does not change it") {
            // 03 section 1.3's honesty invariant, applied to evidence rather than to rendering.
            let home = testPersonnel(offenseSkill: 74, defenseSkill: 72)
            let away = testPersonnel(offenseSkill: 70, defenseSkill: 71)
            let game = GameEngine.play(tier: .pro, home: home, away: away, seed: 2_112)
            let before = game.playByPlayFingerprint
            expectEqual(BoxScore.build(from: game), BoxScore.build(from: game),
                        "the same game produced two different box scores")
            expectEqual(game.playByPlayFingerprint, before, "building a box score changed the game")
        }

        test("a season is the sum of its games") {
            let id = UUID(uuidString: "00000000-0000-4000-C000-000000000003")!
            var season = PlayerSeasonStatistics(playerID: id)
            for _ in 0..<4 {
                season.recordAppearance()
                season.recordProduction(PlayerGameStatistics(
                    playerID: id, carries: 12, rushingYards: 60, receptions: 2, receivingYards: 15,
                    touchdowns: 1
                ))
            }
            expectEqual(season.games, 4)
            expectEqual(season.carries, 48)
            expectEqual(season.rushingYards, 240)
            expectEqual(season.scrimmageYards, 300)
            expectEqual(season.touchdowns, 4)
        }
    }
}
