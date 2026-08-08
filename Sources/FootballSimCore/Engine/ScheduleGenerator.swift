import Foundation

/// Builds a 17-game regular season on the standard rotating formula:
///
/// - 6 games inside your own division, home and away against each rival
/// - 4 against one other division in your conference, rotating yearly
/// - 4 against one division in the other conference, rotating yearly
/// - 2 against the same-place finishers in the two conference divisions you didn't draw
/// - 1 extra cross-conference game against a same-place finisher, hosting in alternate years
public enum ScheduleGenerator {

    private typealias Pairing = (home: UUID, away: UUID, kind: GameKind)

    /// The three ways four divisions can be split into two pairs. Rotating through these gives
    /// every division a different in-conference partner each year — a plain index shift would
    /// pair a division with itself.
    private static let divisionMatchings: [[(Int, Int)]] = [
        [(0, 1), (2, 3)],
        [(0, 2), (1, 3)],
        [(0, 3), (1, 2)],
    ]

    public static func makeSchedule(
        teams: [Team],
        year: Int,
        standings: [UUID: TeamRecord] = [:],
        rng: inout SeededRandom
    ) -> [ScheduledGame] {
        let matching = divisionMatchings[abs(year) % divisionMatchings.count]
        var partnerOf = [Int](repeating: 0, count: Division.allCases.count)
        for (lhs, rhs) in matching {
            partnerOf[lhs] = rhs
            partnerOf[rhs] = lhs
        }

        // Each Liberty division draws a different Frontier division; shifting by a non-zero
        // amount keeps it a one-to-one mapping.
        let interShift = abs(year) % (Division.allCases.count - 1) + 1
        let interPartner = Division.allCases.indices.map { ($0 + interShift) % Division.allCases.count }

        var pairings: [Pairing] = []
        pairings += divisionPairings(teams: teams)
        pairings += intraConferencePairings(teams: teams, matching: matching, year: year)
        pairings += interConferencePairings(teams: teams, mapping: interPartner, year: year)
        pairings += samePlacePairings(
            teams: teams, partnerOf: partnerOf, standings: standings, year: year
        )
        pairings += seventeenthGamePairings(
            teams: teams, interPartner: interPartner, standings: standings, year: year
        )

        return assignWeeks(pairings: pairings, teams: teams, rng: &rng)
    }

    // MARK: - Pairing construction

    private static func divisionPairings(teams: [Team]) -> [Pairing] {
        var pairings: [Pairing] = []
        for conference in Conference.allCases {
            for division in Division.allCases {
                let rivals = teams.filter { $0.conference == conference && $0.division == division }
                for (index, team) in rivals.enumerated() {
                    for other in rivals[(index + 1)...] {
                        pairings.append((team.id, other.id, .division))
                        pairings.append((other.id, team.id, .division))
                    }
                }
            }
        }
        return pairings
    }

    private static func intraConferencePairings(
        teams: [Team],
        matching: [(Int, Int)],
        year: Int
    ) -> [Pairing] {
        var pairings: [Pairing] = []
        for conference in Conference.allCases {
            for (lhsIndex, rhsIndex) in matching {
                pairings += crossDivision(
                    teams: teams,
                    lhsConference: conference, lhsDivision: Division.allCases[lhsIndex],
                    rhsConference: conference, rhsDivision: Division.allCases[rhsIndex],
                    kind: .conference, year: year
                )
            }
        }
        return pairings
    }

    private static func interConferencePairings(
        teams: [Team],
        mapping: [Int],
        year: Int
    ) -> [Pairing] {
        var pairings: [Pairing] = []
        for (index, division) in Division.allCases.enumerated() {
            pairings += crossDivision(
                teams: teams,
                lhsConference: .liberty, lhsDivision: division,
                rhsConference: .frontier, rhsDivision: Division.allCases[mapping[index]],
                kind: .interConference, year: year
            )
        }
        return pairings
    }

    /// Every team in one division plays every team in another: four games each, home field
    /// alternating so the season stays balanced.
    private static func crossDivision(
        teams: [Team],
        lhsConference: Conference,
        lhsDivision: Division,
        rhsConference: Conference,
        rhsDivision: Division,
        kind: GameKind,
        year: Int
    ) -> [Pairing] {
        let lhs = ordered(teams, lhsConference, lhsDivision)
        let rhs = ordered(teams, rhsConference, rhsDivision)
        var pairings: [Pairing] = []
        for (index, team) in lhs.enumerated() {
            for (otherIndex, other) in rhs.enumerated() {
                let homeIsLeft = (index + otherIndex + year) % 2 == 0
                pairings.append(
                    homeIsLeft ? (team.id, other.id, kind) : (other.id, team.id, kind)
                )
            }
        }
        return pairings
    }

    private static func ordered(_ teams: [Team], _ conference: Conference, _ division: Division) -> [Team] {
        teams
            .filter { $0.conference == conference && $0.division == division }
            .sorted { $0.abbreviation < $1.abbreviation }
    }

    /// Teams ranked inside their division by last season's record; table order before year one.
    private static func byFinish(
        _ teams: [Team],
        _ conference: Conference,
        _ division: Division,
        _ standings: [UUID: TeamRecord]
    ) -> [Team] {
        ordered(teams, conference, division).sorted { lhs, rhs in
            let lhsRecord = standings[lhs.id] ?? TeamRecord()
            let rhsRecord = standings[rhs.id] ?? TeamRecord()
            if lhsRecord.winPercentage != rhsRecord.winPercentage {
                return lhsRecord.winPercentage > rhsRecord.winPercentage
            }
            return lhs.abbreviation < rhs.abbreviation
        }
    }

    /// Two games against same-place finishers in the conference divisions not already drawn.
    private static func samePlacePairings(
        teams: [Team],
        partnerOf: [Int],
        standings: [UUID: TeamRecord],
        year: Int
    ) -> [Pairing] {
        var pairings: [Pairing] = []
        for conference in Conference.allCases {
            for lhsIndex in Division.allCases.indices {
                for rhsIndex in Division.allCases.indices {
                    // Build each unordered pair once, skipping the pair already drawn in full.
                    guard lhsIndex < rhsIndex, partnerOf[lhsIndex] != rhsIndex else { continue }
                    let lhs = byFinish(teams, conference, Division.allCases[lhsIndex], standings)
                    let rhs = byFinish(teams, conference, Division.allCases[rhsIndex], standings)
                    for place in 0..<min(lhs.count, rhs.count) {
                        let homeIsLeft = (place + year + lhsIndex) % 2 == 0
                        pairings.append(
                            homeIsLeft
                                ? (lhs[place].id, rhs[place].id, .conference)
                                : (rhs[place].id, lhs[place].id, .conference)
                        )
                    }
                }
            }
        }
        return pairings
    }

    /// The seventeenth game: a same-place cross-conference matchup against a division the team
    /// did not already draw. The hosting conference alternates each year.
    private static func seventeenthGamePairings(
        teams: [Team],
        interPartner: [Int],
        standings: [UUID: TeamRecord],
        year: Int
    ) -> [Pairing] {
        var pairings: [Pairing] = []
        let extraShift = (abs(year) + 1) % (Division.allCases.count - 1) + 1
        let libertyHosts = abs(year) % 2 == 0

        for (index, division) in Division.allCases.enumerated() {
            var partner = (index + extraShift) % Division.allCases.count
            // Must not repeat the division already met in the four-game rotation.
            if partner == interPartner[index] {
                partner = (partner + 1) % Division.allCases.count
            }
            let liberty = byFinish(teams, .liberty, division, standings)
            let frontier = byFinish(teams, .frontier, Division.allCases[partner], standings)
            for place in 0..<min(liberty.count, frontier.count) {
                pairings.append(
                    libertyHosts
                        ? (liberty[place].id, frontier[place].id, .interConference)
                        : (frontier[place].id, liberty[place].id, .interConference)
                )
            }
        }
        return pairings
    }

    // MARK: - Week assignment

    /// Places every pairing into a week so that no team plays twice in a week and every team
    /// gets exactly one bye inside the legal window.
    ///
    /// 32 teams playing 17 games across 18 weeks is an exactly-packed problem: 272 games into
    /// 272 slots, with no spare capacity anywhere. Two things make it solvable:
    ///
    /// 1. Byes per week must be *even*. A week with an odd number of idle teams leaves an odd
    ///    number active, one of whom cannot be paired and is forced into a second bye.
    /// 2. Greedy placement alone paints itself into a corner, so a repair pass afterwards moves
    ///    conflicted games to cheaper weeks until the schedule is clean.
    private static func assignWeeks(
        pairings: [Pairing],
        teams: [Team],
        rng: inout SeededRandom
    ) -> [ScheduledGame] {
        for _ in 0..<12 {
            let byeOf = assignByes(teams: teams, rng: &rng)
            if let weeks = solve(pairings: pairings, byeOf: byeOf, rng: &rng) {
                return zip(pairings, weeks)
                    .map { pairing, week in
                        ScheduledGame(
                            id: rng.uuid(),
                            week: week,
                            homeTeamID: pairing.home,
                            awayTeamID: pairing.away,
                            kind: pairing.kind
                        )
                    }
                    .sorted { lhs, rhs in
                        lhs.week == rhs.week
                            ? lhs.id.uuidString < rhs.id.uuidString
                            : lhs.week < rhs.week
                    }
            }
        }
        return fallbackAssignment(pairings: pairings, rng: &rng)
    }

    /// Hands out one bye per team, an even number of teams per bye week.
    private static func assignByes(teams: [Team], rng: inout SeededRandom) -> [UUID: Int] {
        let byeWeeks = Array(LeagueRules.earliestByeWeek...LeagueRules.latestByeWeek)
        var quota = [Int](repeating: 2, count: byeWeeks.count)
        var remaining = teams.count - quota.reduce(0, +)
        var index = 0
        // Top up in twos so every week keeps an even number of idle teams.
        while remaining >= 2 {
            quota[index % quota.count] += 2
            remaining -= 2
            index += 1
        }

        var slots: [Int] = []
        for (weekIndex, count) in quota.enumerated() {
            slots.append(contentsOf: Array(repeating: byeWeeks[weekIndex], count: count))
        }
        slots = rng.shuffled(slots)

        var byeOf: [UUID: Int] = [:]
        for (teamIndex, team) in rng.shuffled(teams).enumerated() where teamIndex < slots.count {
            byeOf[team.id] = slots[teamIndex]
        }
        return byeOf
    }

    /// Greedy placement followed by conflict repair. Returns a week per pairing, or nil if the
    /// repair pass could not reach a clean schedule.
    private static func solve(
        pairings: [Pairing],
        byeOf: [UUID: Int],
        rng: inout SeededRandom
    ) -> [Int]? {
        let weekCount = LeagueRules.seasonWeeks
        var teamWeekLoad: [UUID: [Int]] = [:]
        for pairing in pairings {
            teamWeekLoad[pairing.home] = [Int](repeating: 0, count: weekCount + 1)
            teamWeekLoad[pairing.away] = [Int](repeating: 0, count: weekCount + 1)
        }

        func penalty(_ team: UUID, _ week: Int, load: Int) -> Int {
            // Playing on your bye week is as bad as a double booking.
            (byeOf[team] == week ? 1 : 0) + max(0, load - 1)
        }

        var assignment = [Int](repeating: 0, count: pairings.count)
        var order = Array(pairings.indices)
        order = rng.shuffled(order)

        for index in order {
            let pairing = pairings[index]
            var bestWeek = 1
            var bestCost = Int.max
            for week in 1...weekCount {
                let homeLoad = teamWeekLoad[pairing.home]![week]
                let awayLoad = teamWeekLoad[pairing.away]![week]
                let cost = penalty(pairing.home, week, load: homeLoad + 1)
                    + penalty(pairing.away, week, load: awayLoad + 1)
                    + (homeLoad + awayLoad)
                if cost < bestCost {
                    bestCost = cost
                    bestWeek = week
                }
            }
            assignment[index] = bestWeek
            teamWeekLoad[pairing.home]![bestWeek] += 1
            teamWeekLoad[pairing.away]![bestWeek] += 1
        }

        func conflicts(of index: Int) -> Int {
            let pairing = pairings[index]
            let week = assignment[index]
            return penalty(pairing.home, week, load: teamWeekLoad[pairing.home]![week])
                + penalty(pairing.away, week, load: teamWeekLoad[pairing.away]![week])
        }

        // Repair in sweeps: collect every conflicted game, move each to its cheapest week,
        // then re-check. Recomputing the conflict list per individual move instead would make
        // each move O(games) and the whole search far too slow to run inside a test suite.
        for _ in 0..<250 {
            let broken = pairings.indices.filter { conflicts(of: $0) > 0 }
            if broken.isEmpty { return assignment }

            for index in rng.shuffled(broken) {
                let pairing = pairings[index]
                let currentWeek = assignment[index]
                teamWeekLoad[pairing.home]![currentWeek] -= 1
                teamWeekLoad[pairing.away]![currentWeek] -= 1

                var bestWeek = currentWeek
                var bestCost = Int.max
                for week in 1...weekCount {
                    let homeLoad = teamWeekLoad[pairing.home]![week]
                    let awayLoad = teamWeekLoad[pairing.away]![week]
                    var cost = penalty(pairing.home, week, load: homeLoad + 1)
                        + penalty(pairing.away, week, load: awayLoad + 1)
                    // Nudge away from the week it just left so the search does not stall.
                    if week == currentWeek { cost += 1 }
                    if cost < bestCost {
                        bestCost = cost
                        bestWeek = week
                    }
                }

                assignment[index] = bestWeek
                teamWeekLoad[pairing.home]![bestWeek] += 1
                teamWeekLoad[pairing.away]![bestWeek] += 1
            }
        }
        return nil
    }

    private static func fallbackAssignment(pairings: [Pairing], rng: inout SeededRandom) -> [ScheduledGame] {
        var busy: [Int: Set<UUID>] = [:]
        var load: [Int: Int] = [:]
        var games: [ScheduledGame] = []
        for pairing in pairings {
            let legal = (1...LeagueRules.seasonWeeks).filter { week in
                !(busy[week]?.contains(pairing.home) ?? false)
                    && !(busy[week]?.contains(pairing.away) ?? false)
            }
            guard let week = legal.min(by: { (load[$0] ?? 0, $0) < (load[$1] ?? 0, $1) }) else { continue }
            busy[week, default: []].insert(pairing.home)
            busy[week, default: []].insert(pairing.away)
            load[week, default: 0] += 1
            games.append(
                ScheduledGame(
                    id: rng.uuid(),
                    week: week,
                    homeTeamID: pairing.home,
                    awayTeamID: pairing.away,
                    kind: pairing.kind
                )
            )
        }
        return games.sorted { $0.week < $1.week }
    }
}
