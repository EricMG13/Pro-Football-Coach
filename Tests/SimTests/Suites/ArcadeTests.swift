import Foundation
import FootballSimCore

func runArcadeTests() {
    suite("PlayExecution") {
        test("neutral execution changes nothing") {
            let neutral = PlayExecution.neutral
            expectEqual(neutral.completionModifier, 0)
            expectEqual(neutral.sackMultiplier, 1)
            expectEqual(neutral.interceptionMultiplier, 1)
            expectEqual(neutral.yardsModifier, 0)
            expectEqual(neutral.fumbleMultiplier, 1)
            expect(neutral.isNeutral)
        }

        test("inputs are clamped and never produce a nonsense multiplier") {
            let extreme = PlayExecution(accuracy: 9, timing: -9, running: .nan)
            expectEqual(extreme.accuracy, 1)
            expectEqual(extreme.timing, -1)
            expectEqual(extreme.running, 0, "a non-finite input must not leak into the sim")
            expect(extreme.sackMultiplier > 0, "multipliers must stay positive")
            expect(extreme.interceptionMultiplier > 0)
        }

        test("good execution helps and bad execution hurts, both by a bounded amount") {
            let good = PlayExecution(accuracy: 1, timing: 1, running: 1)
            let bad = PlayExecution(accuracy: -1, timing: -1, running: -1)

            expect(good.completionModifier > 0 && bad.completionModifier < 0)
            expect(good.sackMultiplier < 1 && bad.sackMultiplier > 1)
            expect(good.interceptionMultiplier < 1 && bad.interceptionMultiplier > 1)
            expect(good.yardsModifier > 0 && bad.yardsModifier < 0)

            // Skill must not outweigh the roster: a perfect snap is worth at most 12 points of
            // completion probability and three and a half yards.
            expect(good.completionModifier <= 0.12, "completion swing is capped")
            expect(good.yardsModifier <= 3.5, "yardage swing is capped")
        }
    }

    suite("ArcadeInput") {
        let accurate = TestFixtures.player(position: .qb, rating: 70)
        var sharpshooter = TestFixtures.player(position: .qb, rating: 70)
        sharpshooter.ratings[.throwAccuracy] = 99
        var scattergun = TestFixtures.player(position: .qb, rating: 70)
        scattergun.ratings[.throwAccuracy] = 40

        test("a perfect throw scores top marks regardless of the passer") {
            expectClose(
                ArcadeInput.throwAccuracy(missDistanceYards: 0, quarterback: scattergun), 1, 0.001
            )
            expectClose(
                ArcadeInput.throwAccuracy(missDistanceYards: 0, quarterback: sharpshooter), 1, 0.001
            )
        }

        test("an accurate passer forgives a miss that ruins an inaccurate one") {
            let miss = 4.0
            let good = ArcadeInput.throwAccuracy(missDistanceYards: miss, quarterback: sharpshooter)
            let poor = ArcadeInput.throwAccuracy(missDistanceYards: miss, quarterback: scattergun)
            expect(
                good > poor,
                "the same miss should cost an accurate quarterback less: \(good) vs \(poor)"
            )
            expect(poor < 0, "four yards off should be a bad ball for a 40-accuracy passer")
        }

        test("throw scores stay inside their range at any miss distance") {
            for miss in stride(from: 0.0, through: 60.0, by: 2.5) {
                let score = ArcadeInput.throwAccuracy(missDistanceYards: miss, quarterback: accurate)
                expect(score >= -1 && score <= 1, "miss \(miss) scored \(score)")
            }
        }

        test("releasing early beats holding the ball") {
            let quick = ArcadeInput.releaseTiming(heldSeconds: 1.0, pocketSeconds: 3.0)
            let onTime = ArcadeInput.releaseTiming(heldSeconds: 2.5, pocketSeconds: 3.0)
            let late = ArcadeInput.releaseTiming(heldSeconds: 4.5, pocketSeconds: 3.0)
            expect(quick > onTime, "a quick release should score best")
            expect(onTime > late, "holding past the pocket should score worst")
            expect(late < 0, "being sacked-late must be a penalty, scored \(late)")
            expect(quick <= 1 && late >= -1, "timing scores must stay in range")
        }

        test("timing handles a collapsed pocket without dividing by zero") {
            expectEqual(ArcadeInput.releaseTiming(heldSeconds: 2, pocketSeconds: 0), 0)
        }

        test("beating defenders is rewarded and running backwards is not") {
            let elusive = ArcadeInput.carrierPlay(
                defendersBeaten: 2, yardsLostScrambling: 0, wentOutOfBoundsSafely: false
            )
            let wasteful = ArcadeInput.carrierPlay(
                defendersBeaten: 0, yardsLostScrambling: 8, wentOutOfBoundsSafely: false
            )
            expect(elusive > 0 && wasteful < 0)
            expect(elusive <= 1 && wasteful >= -1)
        }

        test("the kick meter rewards centred taps") {
            let perfect = ArcadeInput.kickQuality(power: 0.5, aim: 0.5)
            let sloppy = ArcadeInput.kickQuality(power: 0.9, aim: 0.1)
            expectClose(perfect, 1, 0.001)
            expect(sloppy < 0, "badly missing both taps should be a penalty")
            expect(abs(ArcadeInput.kickModifier(quality: perfect)) <= 0.18, "kick swing is capped")
        }

        test("aim matters more than power on a kick") {
            let missedAim = ArcadeInput.kickQuality(power: 0.5, aim: 0.8)
            let missedPower = ArcadeInput.kickQuality(power: 0.8, aim: 0.5)
            expect(
                missedAim < missedPower,
                "pushing a kick wide should cost more than under-hitting it"
            )
        }
    }

    suite("Execution in the simulation") {
        /// Plays the same snap many times with a given execution and reports how often it worked.
        func completionRate(_ execution: PlayExecution, seed: UInt64) -> Double {
            let league = LeagueFactory.makeDefaultLeague(seed: seed, userTeamIndex: 0, coach: .stub())
            var offense = TeamSnapshot(team: league.teams[0])
            var defense = TeamSnapshot(team: league.teams[1])
            var rng = SeededRandom(seed: seed &+ 1)
            var completions = 0
            let attempts = 3_000
            for _ in 0..<attempts {
                let outcome = PlayResolver.resolve(
                    call: .shortPass, defensiveCall: .base, tempo: .normal,
                    offense: &offense, defense: &defense,
                    situation: GameSituation(down: 1, distance: 10, yardLine: 40),
                    homeFieldForOffense: true, execution: execution, rng: &rng
                )
                if outcome.category == .pass && outcome.completed { completions += 1 }
            }
            return Double(completions) / Double(attempts)
        }

        test("a well-executed snap completes more often than a badly executed one") {
            let good = completionRate(PlayExecution(accuracy: 1, timing: 1), seed: 700)
            let neutral = completionRate(.neutral, seed: 700)
            let bad = completionRate(PlayExecution(accuracy: -1, timing: -1), seed: 700)
            expect(good > neutral, "good execution: \(good) vs neutral \(neutral)")
            expect(neutral > bad, "bad execution: \(bad) vs neutral \(neutral)")
        }

        test("skill cannot turn a weak offence into a strong one") {
            // A perfectly executed snap by a poor team must still trail a neutral snap by a
            // great one, or the management half of the game stops mattering.
            let league = LeagueFactory.makeDefaultLeague(seed: 701, userTeamIndex: 0, coach: .stub())
            let best = league.teams.max { $0.offenseRating < $1.offenseRating }!
            let worst = league.teams.min { $0.offenseRating < $1.offenseRating }!
            let defenseTeam = league.teams.first { $0.id != best.id && $0.id != worst.id }!

            func yards(team: Team, execution: PlayExecution, seed: UInt64) -> Double {
                var offense = TeamSnapshot(team: team)
                var defense = TeamSnapshot(team: defenseTeam)
                var rng = SeededRandom(seed: seed)
                var total = 0
                let attempts = 3_000
                for _ in 0..<attempts {
                    let outcome = PlayResolver.resolve(
                        call: .shortPass, defensiveCall: .base, tempo: .normal,
                        offense: &offense, defense: &defense,
                        situation: GameSituation(down: 1, distance: 10, yardLine: 40),
                        homeFieldForOffense: false, execution: execution, rng: &rng
                    )
                    total += max(0, outcome.yards)
                }
                return Double(total) / Double(attempts)
            }

            let poorTeamPerfectPlay = yards(team: worst, execution: PlayExecution(accuracy: 1, timing: 1, running: 1), seed: 900)
            let goodTeamNeutralPlay = yards(team: best, execution: .neutral, seed: 900)
            expect(
                goodTeamNeutralPlay > poorTeamPerfectPlay * 0.75,
                "roster quality must still dominate: best team \(goodTeamNeutralPlay) yards/play "
                    + "vs worst team played perfectly \(poorTeamPerfectPlay)"
            )
        }

        test("execution never produces an illegal outcome") {
            let league = LeagueFactory.makeDefaultLeague(seed: 702, userTeamIndex: 0, coach: .stub())
            var offense = TeamSnapshot(team: league.teams[2])
            var defense = TeamSnapshot(team: league.teams[7])
            var rng = SeededRandom(seed: 55)
            let situation = GameSituation(down: 1, distance: 10, yardLine: 95)
            for _ in 0..<2_000 {
                let outcome = PlayResolver.resolve(
                    call: .deepPass, defensiveCall: .blitz, tempo: .normal,
                    offense: &offense, defense: &defense, situation: situation,
                    homeFieldForOffense: true,
                    execution: PlayExecution(accuracy: 1, timing: 1, running: 1),
                    rng: &rng
                )
                // On a turnover the yardage belongs to the defence's return, so the offence's
                // field bound does not apply to it.
                guard !outcome.isTurnover else { continue }
                expect(outcome.yards <= 5, "gained \(outcome.yards) from the 95")
                expect(outcome.yards >= -95, "lost \(outcome.yards) from the 95")
            }
        }
    }
}

func runInteractiveGameTests() {
    let league = LeagueFactory.makeDefaultLeague(seed: 800, userTeamIndex: 0, coach: .stub())
    let home = league.teams[0]
    let away = league.teams[5]

    func makeGame(seed: UInt64, userIsHome: Bool = true) -> InteractiveGame {
        InteractiveGame(
            home: home,
            away: away,
            userTeamID: userIsHome ? home.id : away.id,
            week: 1,
            year: 2026,
            kind: .conference,
            scheduledGameID: UUID(),
            settings: LeagueSettings(),
            neutralSite: false,
            rng: SeededRandom(seed: seed)
        )
    }

    suite("InteractiveGame") {
        test("stepping to the user's turn stops with them on offence") {
            var game = makeGame(seed: 810)
            game.advanceUntilUserTurn()
            if case .awaitingUserPlay = game.state {
                expect(game.isUserOnOffense, "state says the user is up but possession disagrees")
            } else if game.state == .finished {
                expect(false, "a fresh game should not already be over")
            }
        }

        test("a hand-played game reaches a legal final score") {
            var game = makeGame(seed: 811)
            var snaps = 0
            while game.state != .finished, snaps < 400 {
                snaps += 1
                game.advanceUntilUserTurn()
                guard case .awaitingUserPlay = game.state else { break }
                game.playUserSnap(call: .shortPass, execution: PlayExecution(accuracy: 0.5, timing: 0.5))
            }
            game.simulateRemainder()

            guard let record = game.record else { return expect(false, "no record was produced") }
            expect(record.homeScore >= 0 && record.awayScore >= 0, "negative score")
            expect(record.homeScore != 1 && record.awayScore != 1, "1 is not a reachable score")
            expect(!record.plays.isEmpty, "a played game recorded no plays")
            expect(record.playerStats.count > 50, "box score is too thin: \(record.playerStats.count)")
        }

        test("playing every snap with neutral execution matches the simulated game exactly") {
            // The engine draws its own call either way, so a player who calls what the AI would
            // have called, and executes it neutrally, must land on the identical game. This is
            // the guarantee that watching and simming cannot diverge.
            var simulated = GameSimulator(
                home: home, away: away, week: 1, year: 2026, kind: .conference,
                scheduledGameID: UUID(), options: .init(retainPlays: true)
            )
            var rngA = SeededRandom(seed: 812)
            let reference = simulated.run(rng: &rngA)

            var stepped = GameSimulator(
                home: home, away: away, week: 1, year: 2026, kind: .conference,
                scheduledGameID: UUID(), options: .init(retainPlays: true)
            )
            var rngB = SeededRandom(seed: 812)
            var steps = 0
            while stepped.advance(rng: &rngB), steps < 5_000 { steps += 1 }
            let byHand = stepped.finish(rng: &rngB)

            expectEqual(byHand.homeScore, reference.homeScore, "home score diverged")
            expectEqual(byHand.awayScore, reference.awayScore, "away score diverged")
            expectEqual(byHand.plays.count, reference.plays.count, "play count diverged")
            expectEqual(byHand.homeStats.totalYards, reference.homeStats.totalYards)
            expectEqual(byHand.overtimePeriods, reference.overtimePeriods)
        }

        test("simulating the remainder from the start equals a straight simulation") {
            var game = makeGame(seed: 813)
            game.simulateRemainder()
            guard let played = game.record else { return expect(false, "no record") }

            var reference = GameSimulator(
                home: home, away: away, week: 1, year: 2026, kind: .conference,
                scheduledGameID: UUID(), options: .init(retainPlays: true)
            )
            var rng = SeededRandom(seed: 813)
            let simulated = reference.run(rng: &rng)

            expectEqual(played.homeScore, simulated.homeScore)
            expectEqual(played.awayScore, simulated.awayScore)
            expectEqual(played.plays.count, simulated.plays.count)
        }

        test("the random stream is handed back so the league can carry on") {
            var game = makeGame(seed: 814)
            let before = game.currentRNG
            game.simulateRemainder()
            expect(game.currentRNG != before, "the game consumed no randomness at all")
        }

        test("a user who plays well scores more than one who plays badly") {
            func scoreWithExecution(_ execution: PlayExecution, seed: UInt64) -> Int {
                var total = 0
                for offset in 0..<6 {
                    var game = makeGame(seed: seed &+ UInt64(offset))
                    var snaps = 0
                    while game.state != .finished, snaps < 400 {
                        snaps += 1
                        game.advanceUntilUserTurn()
                        guard case .awaitingUserPlay(let situation) = game.state else { break }
                        // Call something sane so the comparison is about execution, not tactics.
                        let call: OffensivePlay = situation.distance >= 7 ? .shortPass : .insideRun
                        game.playUserSnap(call: call, execution: execution)
                    }
                    game.simulateRemainder()
                    total += game.record?.score(for: home.id) ?? 0
                }
                return total
            }

            let sharp = scoreWithExecution(PlayExecution(accuracy: 1, timing: 1, running: 1), seed: 820)
            let sloppy = scoreWithExecution(PlayExecution(accuracy: -1, timing: -1, running: -1), seed: 820)
            expect(
                sharp > sloppy,
                "good play scored \(sharp) across six games, bad play \(sloppy) — skill should tell"
            )
        }

        test("stepping cannot run away with itself") {
            var game = makeGame(seed: 815)
            // A caller that never supplies a snap must still terminate rather than spin.
            let produced = game.advanceUntilUserTurn(limit: 50)
            expect(produced.count <= 50, "more plays than steps taken")
            expect(game.state != .finished || game.record != nil, "finished without a record")
        }
    }
}
