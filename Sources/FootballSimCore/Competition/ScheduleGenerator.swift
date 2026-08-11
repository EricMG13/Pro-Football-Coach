import Foundation

public enum ScheduleGenerator {
    public static func regularSeason(
        seed: UInt64,
        season: Int,
        programmes: [Programme],
        proTeams: [ProTeam]
    ) -> [ScheduledGame] {
        let collegeGroups = Dictionary(uniqueKeysWithValues: programmes.compactMap { programme in
            programme.conferenceID.map { (programme.id, $0) }
        })
        let proGroups = Dictionary(uniqueKeysWithValues: proTeams.compactMap { team in
            team.divisionID.map { (team.id, $0) }
        })
        return tierSchedule(
            seed: seed,
            season: season,
            tier: .college,
            memberIDs: programmes.map(\.id),
            groups: collegeGroups,
            gamesPerTeam: CollegeRules.gamesPerRegularSeason,
            weeks: CollegeRules.regularSeasonWeeks
        ) + tierSchedule(
            seed: seed,
            season: season,
            tier: .pro,
            memberIDs: proTeams.map(\.id),
            groups: proGroups,
            gamesPerTeam: ProRules.gamesPerRegularSeason,
            weeks: ProRules.regularSeasonWeeks
        )
    }

    private struct Pair: Hashable {
        let first: UUID
        let second: UUID

        init(_ lhs: UUID, _ rhs: UUID) {
            if lhs.uuidString < rhs.uuidString {
                first = lhs
                second = rhs
            } else {
                first = rhs
                second = lhs
            }
        }
    }

    private static let pairingAttemptsPerWeek = 2_048

    private static func tierSchedule(
        seed: UInt64,
        season: Int,
        tier: Tier,
        memberIDs: [UUID],
        groups: [UUID: UUID],
        gamesPerTeam: Int,
        weeks: Int
    ) -> [ScheduledGame] {
        let members = memberIDs.sorted { $0.uuidString < $1.uuidString }
        guard members.count.isMultiple(of: 2), weeks == gamesPerTeam + 1 else { return [] }
        let byeGroups = balancedEvenGroups(memberCount: members.count, groupCount: weeks)
        var byeWeekByMember: [UUID: Int] = [:]
        var cursor = 0
        for (weekIndex, size) in byeGroups.enumerated() {
            for id in members[cursor..<(cursor + size)] {
                byeWeekByMember[id] = weekIndex + 1
            }
            cursor += size
        }

        var usedPairs: Set<Pair> = []
        var weeklyPairs: [[Pair]] = []
        for week in 1...weeks {
            let active = members.filter { byeWeekByMember[$0] != week }
            guard let pairs = pair(
                active,
                avoiding: usedPairs,
                preferredGroups: groups,
                seed: scheduleSeed(seed: seed, season: season, tier: tier, week: week)
            ) else {
                return roundRobinFallback(
                    seed: seed,
                    season: season,
                    tier: tier,
                    members: members,
                    gamesPerTeam: gamesPerTeam,
                    weeks: weeks
                )
            }
            usedPairs.formUnion(pairs)
            weeklyPairs.append(pairs)
        }

        return makeGames(
            seed: seed,
            season: season,
            tier: tier,
            weeklyPairs: weeklyPairs
        )
    }

    /// Even bye groups keep every week's active population pairable. Empty groups are legal for
    /// leagues with more weeks than pairs, such as the 32-team pro league's 18-week season.
    private static func balancedEvenGroups(memberCount: Int, groupCount: Int) -> [Int] {
        var groups = Array(repeating: 0, count: groupCount)
        var remaining = memberCount
        var index = 0
        while remaining >= 2 {
            groups[index % groupCount] += 2
            remaining -= 2
            index += 1
        }
        return groups
    }

    private static func pair(
        _ members: [UUID],
        avoiding usedPairs: Set<Pair>,
        preferredGroups: [UUID: UUID],
        seed: UInt64
    ) -> [Pair]? {
        guard members.count.isMultiple(of: 2) else { return nil }
        for attempt in 0..<pairingAttemptsPerWeek {
            var rng = SeededRandom(seed: SeededRandom.derive(
                from: seed,
                scope: .game,
                ordinal: attempt
            ))
            var remaining = rng.shuffled(members)
            var result: [Pair] = []
            var failed = false

            while !remaining.isEmpty {
                let first = remaining.removeLast()
                let valid = remaining.indices.filter {
                    !usedPairs.contains(Pair(first, remaining[$0]))
                }
                guard !valid.isEmpty else {
                    failed = true
                    break
                }
                let preferred = valid.filter {
                    preferredGroups[first] != nil
                        && preferredGroups[first] == preferredGroups[remaining[$0]]
                }
                let pool = preferred.isEmpty ? valid : preferred
                let selectedPoolIndex = rng.int(in: 0...(pool.count - 1))
                let selectedIndex = pool[selectedPoolIndex]
                result.append(Pair(first, remaining.remove(at: selectedIndex)))
            }
            if !failed { return result }
        }
        return nil
    }

    /// Guaranteed-valid final fallback: take distinct factors of a complete round robin and leave
    /// the final week empty. It sacrifices bye distribution, never schedule integrity.
    private static func roundRobinFallback(
        seed: UInt64,
        season: Int,
        tier: Tier,
        members: [UUID],
        gamesPerTeam: Int,
        weeks: Int
    ) -> [ScheduledGame] {
        var rotation = members
        var weeklyPairs: [[Pair]] = []
        for _ in 0..<gamesPerTeam {
            var pairs: [Pair] = []
            for index in 0..<(rotation.count / 2) {
                pairs.append(Pair(rotation[index], rotation[rotation.count - 1 - index]))
            }
            weeklyPairs.append(pairs)
            let fixed = rotation.removeFirst()
            let moved = rotation.removeLast()
            rotation.insert(moved, at: 0)
            rotation.insert(fixed, at: 0)
        }
        weeklyPairs.append(contentsOf: Array(
            repeating: [],
            count: max(0, weeks - weeklyPairs.count)
        ))
        return makeGames(
            seed: seed,
            season: season,
            tier: tier,
            weeklyPairs: weeklyPairs
        )
    }

    private static func makeGames(
        seed: UInt64,
        season: Int,
        tier: Tier,
        weeklyPairs: [[Pair]]
    ) -> [ScheduledGame] {
        var games: [ScheduledGame] = []
        for (weekIndex, pairs) in weeklyPairs.enumerated() {
            for (pairIndex, pair) in pairs.enumerated() {
                var rng = SeededRandom(seed: SeededRandom.derive(
                    from: scheduleSeed(
                        seed: seed,
                        season: season,
                        tier: tier,
                        week: weekIndex + 1
                    ),
                    scope: .snap,
                    ordinal: pairIndex
                ))
                let firstIsHome = (season + weekIndex + pairIndex) % 2 == 0
                games.append(ScheduledGame(
                    id: rng.uuid(),
                    season: season,
                    tier: tier,
                    week: weekIndex + 1,
                    stage: .regularSeason,
                    homeID: firstIsHome ? pair.first : pair.second,
                    awayID: firstIsHome ? pair.second : pair.first
                ))
            }
        }
        return games
    }

    private static func scheduleSeed(
        seed: UInt64,
        season: Int,
        tier: Tier,
        week: Int
    ) -> UInt64 {
        let seasonSeed = SeededRandom.derive(from: seed, scope: .season, ordinal: season)
        let tierOrdinal = Tier.allCases.firstIndex(of: tier) ?? 0
        let tierSeed = SeededRandom.derive(
            from: seasonSeed,
            scope: .scheduler,
            ordinal: tierOrdinal
        )
        return SeededRandom.derive(from: tierSeed, scope: .week, ordinal: week)
    }
}
