import Foundation
import FootballSimCore

/// Aggregates a batch of simulated games so the calibration suite can assert on league-wide
/// rates rather than any single result.
struct SimulationSample {
    var games = 0
    var teamGames = 0
    var points = 0
    var passingYards = 0
    var rushingYards = 0
    var passAttempts = 0
    var completions = 0
    var interceptions = 0
    var sacks = 0
    var fieldGoalsMade = 0
    var fieldGoalsAttempted = 0
    var overtimeGames = 0
    var homeWins = 0
    var decidedGames = 0
    var quarterPoints = [0, 0, 0, 0]
    var explosivePlays = 0
    var longTouchdowns = 0
    var safeties = 0
    var totalPlays = 0
    var targetsByPosition: [Position: Int] = [:]
    var targetsByPlayer: [UUID: Int] = [:]
    var teamTargetTotals: [UUID: Int] = [:]
    var playerTeam: [UUID: UUID] = [:]

    /// Largest share of a team's targets any single receiver holds across the whole sample.
    var maxReceiverShare: Double {
        var largest = 0.0
        for (playerID, targets) in targetsByPlayer {
            guard let teamID = playerTeam[playerID], let total = teamTargetTotals[teamID], total > 200
            else { continue }
            largest = max(largest, Double(targets) / Double(total))
        }
        return largest
    }

    var pointsPerTeamGame: Double { Double(points) / Double(teamGames) }
    var passYardsPerTeamGame: Double { Double(passingYards) / Double(teamGames) }
    var rushYardsPerTeamGame: Double { Double(rushingYards) / Double(teamGames) }
    var completionPercentage: Double { Double(completions) / Double(passAttempts) * 100 }
    var interceptionsPerTeamGame: Double { Double(interceptions) / Double(teamGames) }
    var sacksPerTeamGame: Double { Double(sacks) / Double(teamGames) }
    var fieldGoalPercentage: Double { Double(fieldGoalsMade) / Double(max(1, fieldGoalsAttempted)) * 100 }
    var overtimeRate: Double { Double(overtimeGames) / Double(games) }
    var homeWinRate: Double { Double(homeWins) / Double(max(1, decidedGames)) }
    var fourthQuarterShare: Double {
        Double(quarterPoints[3]) / Double(max(1, quarterPoints.reduce(0, +)))
    }
    var explosivePlaysPerGame: Double { Double(explosivePlays) / Double(games) }
    var longTouchdownsPerGame: Double { Double(longTouchdowns) / Double(games) }
    var safetiesPerGame: Double { Double(safeties) / Double(games) }
    var playsPerTeamGame: Double { Double(totalPlays) / Double(teamGames) }

    func targetShare(_ position: Position) -> Double {
        let total = targetsByPosition.values.reduce(0, +)
        guard total > 0 else { return 0 }
        return Double(targetsByPosition[position] ?? 0) / Double(total)
    }
}

enum SimHarness {
    /// Simulates `count` games between randomly drawn league teams and aggregates the results.
    static func sample(count: Int, seed: UInt64, retainPlays: Bool = false) -> SimulationSample {
        let league = LeagueFactory.makeDefaultLeague(seed: seed, userTeamIndex: 0, coach: .stub())
        var rng = SeededRandom(seed: seed &+ 7_777)
        var sample = SimulationSample()

        for index in 0..<count {
            let homeIndex = rng.int(in: 0...(league.teams.count - 1))
            var awayIndex = rng.int(in: 0...(league.teams.count - 1))
            if awayIndex == homeIndex { awayIndex = (awayIndex + 1) % league.teams.count }
            let home = league.teams[homeIndex]
            let away = league.teams[awayIndex]

            var simulator = GameSimulator(
                home: home,
                away: away,
                week: index % 18 + 1,
                year: 2026,
                kind: .conference,
                scheduledGameID: rng.uuid(),
                options: .init(retainPlays: retainPlays, injuriesEnabled: true)
            )
            let record = simulator.run(rng: &rng)
            accumulate(record: record, home: home, away: away, into: &sample)
        }
        return sample
    }

    static func accumulate(record: GameRecord, home: Team, away: Team, into sample: inout SimulationSample) {
        sample.games += 1
        sample.teamGames += 2
        if record.wentToOvertime { sample.overtimeGames += 1 }
        if !record.isTie {
            sample.decidedGames += 1
            if record.winnerID == record.homeTeamID { sample.homeWins += 1 }
        }

        for stats in [record.homeStats, record.awayStats] {
            sample.points += stats.points
            sample.passingYards += stats.passingYards
            sample.rushingYards += stats.rushingYards
            sample.sacks += stats.sacks
            sample.totalPlays += stats.plays
            for (index, value) in stats.quarterPoints.enumerated() where index < 4 {
                sample.quarterPoints[index] += value
            }
        }

        for (playerID, line) in record.playerStats {
            sample.passAttempts += line.passAttempts
            sample.completions += line.completions
            sample.interceptions += line.interceptionsThrown
            sample.fieldGoalsMade += line.fieldGoalsMade
            sample.fieldGoalsAttempted += line.fieldGoalsAttempted
            if line.targets > 0 {
                let owner = home.player(id: playerID) != nil ? home : away
                sample.targetsByPosition[owner.player(id: playerID)?.position ?? .wr, default: 0] += line.targets
                sample.targetsByPlayer[playerID, default: 0] += line.targets
                sample.teamTargetTotals[owner.id, default: 0] += line.targets
                sample.playerTeam[playerID] = owner.id
            }
        }

        for play in record.plays {
            if play.yards >= 25 && (play.category == .run || play.category == .pass || play.category == .touchdown) {
                sample.explosivePlays += 1
            }
            if play.category == .touchdown && play.yards >= 40 { sample.longTouchdowns += 1 }
            if play.description.contains("Safety") { sample.safeties += 1 }
        }
    }
}

func runGameSimulatorTests() {
    let league = LeagueFactory.makeDefaultLeague(seed: 21, userTeamIndex: 0, coach: .stub())

    suite("GameSimulator mechanics") {
        test("same seed reproduces the same game exactly") {
            func play() -> GameRecord {
                var rng = SeededRandom(seed: 4_242)
                var simulator = GameSimulator(
                    home: league.teams[0], away: league.teams[1], week: 1, year: 2026,
                    kind: .conference, scheduledGameID: UUID(),
                    options: .init(retainPlays: true)
                )
                return simulator.run(rng: &rng)
            }
            let first = play(), second = play()
            expectEqual(first.homeScore, second.homeScore)
            expectEqual(first.awayScore, second.awayScore)
            expectEqual(first.plays.count, second.plays.count)
            expectEqual(first.homeStats.totalYards, second.homeStats.totalYards)
        }

        test("retaining plays does not change the outcome") {
            func play(retain: Bool) -> GameRecord {
                var rng = SeededRandom(seed: 909)
                var simulator = GameSimulator(
                    home: league.teams[3], away: league.teams[9], week: 4, year: 2026,
                    kind: .conference, scheduledGameID: UUID(),
                    options: .init(retainPlays: retain)
                )
                return simulator.run(rng: &rng)
            }
            let watched = play(retain: true)
            let simmed = play(retain: false)
            expectEqual(watched.homeScore, simmed.homeScore, "watched vs simmed home score")
            expectEqual(watched.awayScore, simmed.awayScore, "watched vs simmed away score")
            expectEqual(watched.homeStats.totalYards, simmed.homeStats.totalYards)
            expectEqual(watched.playerStats.count, simmed.playerStats.count)
        }

        test("team passing yards equal the sum of receiving yards") {
            var rng = SeededRandom(seed: 55)
            for _ in 0..<12 {
                let homeIndex = rng.int(in: 0...31)
                let home = league.teams[homeIndex]
                // Offset guarantees a different opponent; picking again could repeat the index
                // and have a team play itself, which makes the stat comparison meaningless.
                let away = league.teams[(homeIndex + rng.int(in: 1...31)) % 32]
                var simulator = GameSimulator(
                    home: home, away: away, week: 1, year: 2026,
                    kind: .conference, scheduledGameID: UUID(), options: .init(retainPlays: true)
                )
                let record = simulator.run(rng: &rng)

                for team in [home, away] {
                    let ids = Set(team.roster.map(\.id))
                    let lines = record.playerStats.filter { ids.contains($0.key) }.values
                    let passing = lines.reduce(0) { $0 + $1.passingYards }
                    let receiving = lines.reduce(0) { $0 + $1.receivingYards }
                    let rushing = lines.reduce(0) { $0 + $1.rushingYards }
                    expectEqual(passing, receiving, "\(team.abbreviation) pass/receive mismatch")
                    let teamStats = record.stats(for: team.id)
                    // Team passing yards are net of sacks; gross passing is the receivers' total.
                    expect(
                        teamStats.passingYards <= passing,
                        "\(team.abbreviation) net passing above gross"
                    )
                    expectEqual(teamStats.rushingYards, rushing, "\(team.abbreviation) rushing mismatch")
                }
            }
        }

        test("scores are composed of legal scoring plays") {
            var rng = SeededRandom(seed: 77)
            var impossible = 0
            for _ in 0..<40 {
                var simulator = GameSimulator(
                    home: league.teams[2], away: league.teams[15], week: 2, year: 2026,
                    kind: .conference, scheduledGameID: UUID(), options: .init()
                )
                let record = simulator.run(rng: &rng)
                // 1 point can never be a team's whole score.
                if record.homeScore == 1 || record.awayScore == 1 { impossible += 1 }
                if record.homeScore < 0 || record.awayScore < 0 { impossible += 1 }
                expectEqual(
                    record.homeStats.quarterPoints.reduce(0, +) <= record.homeScore, true,
                    "quarter points exceed final score"
                )
            }
            expectEqual(impossible, 0, "impossible score appeared")
        }

        test("a regular-season game never ends tied after overtime rules allow one period") {
            var rng = SeededRandom(seed: 88)
            var ties = 0
            var games = 0
            for _ in 0..<200 {
                var simulator = GameSimulator(
                    home: league.teams[5], away: league.teams[6], week: 3, year: 2026,
                    kind: .conference, scheduledGameID: UUID(), options: .init()
                )
                let record = simulator.run(rng: &rng)
                games += 1
                if record.isTie { ties += 1 }
            }
            // Ties are legal but must be rare.
            expect(Double(ties) / Double(games) < 0.03, "tie rate \(Double(ties) / Double(games))")
        }

        test("playoff games always produce a winner") {
            var rng = SeededRandom(seed: 99)
            for _ in 0..<60 {
                var simulator = GameSimulator(
                    home: league.teams[7], away: league.teams[8], week: 19, year: 2026,
                    kind: .championship, scheduledGameID: UUID(), options: .init()
                )
                let record = simulator.run(rng: &rng)
                expect(!record.isTie, "a playoff game ended in a tie")
            }
        }

        test("play log stays inside the field and the clock") {
            var rng = SeededRandom(seed: 121)
            var simulator = GameSimulator(
                home: league.teams[10], away: league.teams[20], week: 5, year: 2026,
                kind: .conference, scheduledGameID: UUID(), options: .init(retainPlays: true)
            )
            let record = simulator.run(rng: &rng)
            expect(!record.plays.isEmpty, "no plays were recorded")
            var violations = 0
            for play in record.plays {
                if play.yardLine < 0 || play.yardLine > 100 { violations += 1 }
                if play.clockSeconds < 0 || play.clockSeconds > LeagueRules.quarterLengthSeconds { violations += 1 }
                if play.down < 1 || play.down > 4 { violations += 1 }
                if play.quarter < 1 { violations += 1 }
            }
            expectEqual(violations, 0, "play log left the field or the clock")
        }

        test("a much better team usually wins") {
            let strong = league.teams.max { $0.overallRating < $1.overallRating }!
            let weak = league.teams.min { $0.overallRating < $1.overallRating }!
            var rng = SeededRandom(seed: 303)
            var strongWins = 0
            let games = 400
            for index in 0..<games {
                // Alternate home field so the result is about the rosters, not the venue.
                let homeIsStrong = index % 2 == 0
                var simulator = GameSimulator(
                    home: homeIsStrong ? strong : weak,
                    away: homeIsStrong ? weak : strong,
                    week: 1, year: 2026, kind: .conference,
                    scheduledGameID: UUID(), options: .init()
                )
                let record = simulator.run(rng: &rng)
                if record.winnerID == strong.id { strongWins += 1 }
            }
            let rate = Double(strongWins) / Double(games)
            expect(
                rate >= 0.72,
                "best team beat worst only \(Int(rate * 100))% of the time (gap \(Int(strong.overallRating - weak.overallRating)) OVR)"
            )
        }

        test("simulating a game is fast enough for bulk seasons") {
            var rng = SeededRandom(seed: 404)
            let start = Date()
            for _ in 0..<200 {
                var simulator = GameSimulator(
                    home: league.teams[0], away: league.teams[1], week: 1, year: 2026,
                    kind: .conference, scheduledGameID: UUID(), options: .init()
                )
                _ = simulator.run(rng: &rng)
            }
            let msPerGame = Date().timeIntervalSince(start) * 1000 / 200
            expect(msPerGame < 20, "\(String(format: "%.1f", msPerGame)) ms per game exceeds the 20 ms budget")
        }
    }

    suite("Calibration") {
        let sample = SimHarness.sample(count: 600, seed: 31, retainPlays: true)

        test("scoring sits in the realistic band") {
            expectIn(sample.pointsPerTeamGame, 20...26, "points per team game")
        }

        test("passing volume is realistic") {
            expectIn(sample.passYardsPerTeamGame, 195...245, "pass yards per team game")
            expectIn(sample.completionPercentage, 61...67, "completion percentage")
        }

        test("rushing volume is realistic") {
            expectIn(sample.rushYardsPerTeamGame, 100...130, "rush yards per team game")
        }

        test("turnovers and pressure are realistic") {
            expectIn(sample.interceptionsPerTeamGame, 0.6...1.1, "interceptions per team game")
            expectIn(sample.sacksPerTeamGame, 2.0...3.1, "sacks per team game")
        }

        test("kicking accuracy is realistic") {
            expectIn(sample.fieldGoalPercentage, 80...90, "field goal percentage")
        }

        test("overtime and home advantage are realistic") {
            expectIn(sample.overtimeRate, 0.008...0.14, "overtime rate")
            // Home win rate is measured over 600 games, so its standard error is around two
            // percentage points — a tighter band would fail on sampling noise rather than on a
            // real regression. Real leagues have posted seasons close to even, too.
            expectIn(sample.homeWinRate, 0.50...0.60, "home win rate")
        }

        test("play volume is realistic") {
            expectIn(sample.playsPerTeamGame, 55...72, "offensive plays per team game")
        }

        test("fourth quarter carries its share of the scoring") {
            expectIn(sample.fourthQuarterShare, 0.22...0.32, "share of points scored in Q4")
        }

        test("explosive plays happen without dominating") {
            expectIn(sample.explosivePlaysPerGame, 3...9, "plays of 25+ yards per game")
            expectIn(sample.longTouchdownsPerGame, 0.2...1.2, "touchdowns of 40+ yards per game")
        }

        test("freak events stay rare") {
            expect(sample.safetiesPerGame <= 0.05, "safeties per game \(sample.safetiesPerGame)")
        }

        test("targets are spread across the offence") {
            expectIn(sample.targetShare(.te), 0.15...0.26, "tight end target share")
            expectIn(sample.targetShare(.rb), 0.10...0.28, "running back target share")
            expect(
                sample.maxReceiverShare <= 0.45,
                "one receiver took \(Int(sample.maxReceiverShare * 100))% of a team's targets"
            )
        }
    }
}
