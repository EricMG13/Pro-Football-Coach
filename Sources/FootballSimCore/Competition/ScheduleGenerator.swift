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

    // ponytail: cap randomized search; the deterministic round-robin fallback preserves legality
    // when conference preferences cannot be satisfied quickly.
    private static let pairingAttemptsPerWeek = 8

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
        return constrainedPair(
            members,
            avoiding: usedPairs,
            preferredGroups: preferredGroups,
            seed: seed
        )
    }

    /// Last resort before the round-robin fallback, and the reason that fallback is now close to
    /// unreachable.
    ///
    /// The randomized greedy above takes whichever member the shuffle left on the end, which can
    /// strand the final two on a pairing they have already played; eight attempts then all
    /// dead-end and the whole tier drops to `roundRobinFallback`, whose byes all land in the one
    /// leftover week. That is a legal slate by game count and an illegal one by bye distribution
    /// — 32 professional teams idle in the same week — and until the season-by-seed sweep in
    /// `CompetitionTests` there was nothing that looked at any season but the first.
    ///
    /// Taking the member with the fewest legal partners first spends the scarce options while
    /// they are still interchangeable. It is O(n^3) in the week's active population, so it runs
    /// only on a week that already failed every randomized attempt.
    private static func constrainedPair(
        _ members: [UUID],
        avoiding usedPairs: Set<Pair>,
        preferredGroups: [UUID: UUID],
        seed: UInt64
    ) -> [Pair]? {
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: seed,
            scope: .game,
            ordinal: pairingAttemptsPerWeek
        ))
        var remaining = rng.shuffled(members)
        var result: [Pair] = []
        while !remaining.isEmpty {
            var chosen = 0
            var fewest = Int.max
            for index in remaining.indices {
                let options = legalPartners(
                    of: index,
                    among: remaining,
                    avoiding: usedPairs
                ).count
                if options < fewest {
                    fewest = options
                    chosen = index
                }
            }
            guard fewest > 0 else { return nil }
            let first = remaining.remove(at: chosen)
            let valid = remaining.indices.filter {
                !usedPairs.contains(Pair(first, remaining[$0]))
            }
            let preferred = valid.filter {
                preferredGroups[first] != nil
                    && preferredGroups[first] == preferredGroups[remaining[$0]]
            }
            let pool = preferred.isEmpty ? valid : preferred
            // Most-constrained partner too, for the same reason: an opponent with one option left
            // must take it now or lose it to someone who had several.
            let partner = pool.min {
                let left = legalPartners(of: $0, among: remaining, avoiding: usedPairs).count
                let right = legalPartners(of: $1, among: remaining, avoiding: usedPairs).count
                return left == right ? $0 < $1 : left < right
            }
            guard let partner else { return nil }
            result.append(Pair(first, remaining.remove(at: partner)))
        }
        return result
    }

    private static func legalPartners(
        of index: Int,
        among members: [UUID],
        avoiding usedPairs: Set<Pair>
    ) -> [Int] {
        members.indices.filter {
            $0 != index && !usedPairs.contains(Pair(members[index], members[$0]))
        }
    }

    /// Deterministic final fallback. Rotate the balanced bye assignment until the constrained
    /// matcher can complete every week; if none can, preserve the generator's existing empty-slate
    /// failure contract instead of returning a known-invalid season.
    package static func roundRobinFallback(
        seed: UInt64,
        season: Int,
        tier: Tier,
        members: [UUID],
        gamesPerTeam: Int,
        weeks: Int
    ) -> [ScheduledGame] {
        guard members.count.isMultiple(of: 2), weeks == gamesPerTeam + 1 else { return [] }
        let byeGroups = balancedEvenGroups(memberCount: members.count, groupCount: weeks)

        for offset in members.indices {
            let rotated = Array(members[offset...]) + Array(members[..<offset])
            var byeWeekByMember: [UUID: Int] = [:]
            var cursor = 0
            for (weekIndex, size) in byeGroups.enumerated() {
                for id in rotated[cursor..<(cursor + size)] {
                    byeWeekByMember[id] = weekIndex + 1
                }
                cursor += size
            }

            var usedPairs: Set<Pair> = []
            var weeklyPairs: [[Pair]] = []
            var completed = true
            for week in 1...weeks {
                let active = members.filter { byeWeekByMember[$0] != week }
                let attemptSeed = SeededRandom.derive(
                    from: scheduleSeed(seed: seed, season: season, tier: tier, week: week),
                    scope: .game,
                    ordinal: offset
                )
                guard let pairs = constrainedPair(
                    active,
                    avoiding: usedPairs,
                    preferredGroups: [:],
                    seed: attemptSeed
                ) else {
                    completed = false
                    break
                }
                usedPairs.formUnion(pairs)
                weeklyPairs.append(pairs)
            }
            if completed {
                return makeGames(
                    seed: seed,
                    season: season,
                    tier: tier,
                    weeklyPairs: weeklyPairs
                )
            }
        }
        return []
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
