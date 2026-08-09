import Foundation

/// The hierarchical seed contract from `docs/03-MATCH-ENGINE.md` §3.
///
/// Determinism is Tier A: a given seed plus a given input state reproduces a match exactly, across
/// processes and app launches. That needs more than one good generator — it needs every point in the
/// simulation to derive its stream from a *stated* path rather than from wherever the caller happened
/// to be in a shared sequence.
///
///     league → season → week → game → drive → snap
///
/// Deriving each level from its parent plus its own identifier buys two things. Replaying one snap
/// does not require replaying the season that led to it, so a bug reproduces in isolation. And
/// inserting work at one level — an extra AI pass during a week, say — cannot shift the streams of
/// levels beside it, which is the failure mode that makes "same seed, different league" appear
/// months after the mistake.
///
/// Nothing here reads `hashValue`. Swift salts it per process, so a seed derived from one is stable
/// within a run and worthless between runs; the prior build seeded free-agent bidding that way and
/// every in-process test passed while every launch produced a different league. `ContractTests`
/// scans the engine to keep it from coming back.
public enum SeedPath {
    /// SplitMix64's finalizer, used here as a mixing step rather than as a generator.
    ///
    /// It avalanches well — one changed bit in either input changes about half the output bits — so
    /// sibling components that differ by 1 (week 3 vs week 4) produce unrelated streams rather than
    /// neighbouring ones. Deriving a child seed by adding or XOR-ing the component would leave
    /// sibling streams correlated, which shows up as leagues that rhyme.
    private static func mix(_ seed: UInt64, _ component: UInt64) -> UInt64 {
        var z = seed &+ (component &* 0x9E37_79B9_7F4A_7C15)
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Signed indices fold through their bit pattern so a negative never traps and never collides
    /// with its positive twin.
    private static func component(_ value: Int) -> UInt64 {
        UInt64(bitPattern: Int64(value))
    }

    /// Root of the tree. Derived from the league's identifier bytes via `SeededRandom.seed(from:)`.
    public static func league(_ league: UUID) -> UInt64 {
        SeededRandom.seed(from: league)
    }

    /// A season within a league. Keyed by calendar year so a save that resumes mid-career derives
    /// the same seasons it would have derived on a straight run.
    public static func season(_ parent: UInt64, year: Int) -> UInt64 {
        mix(parent, component(year))
    }

    /// A week within a season. Week numbers are 1-based; week 0 is reserved for preseason work so
    /// that adding a preseason later does not renumber the regular season.
    public static func week(_ parent: UInt64, week: Int) -> UInt64 {
        mix(parent, component(week))
    }

    /// A single game within a week.
    ///
    /// Keyed by the two team identifiers rather than by a slot index, so a schedule change elsewhere
    /// in the week cannot move this game's stream. Home and away are mixed in order, so a fixture
    /// and its reverse are distinct — home advantage is a real term in the engine and the two games
    /// must not share a stream.
    public static func game(_ parent: UInt64, home: UUID, away: UUID) -> UInt64 {
        mix(mix(parent, SeededRandom.seed(from: home)), SeededRandom.seed(from: away))
    }

    /// A drive within a game, by 0-based index in the order drives are played.
    public static func drive(_ parent: UInt64, index: Int) -> UInt64 {
        mix(parent, component(index))
    }

    /// A snap within a drive, by 0-based index.
    ///
    /// This is the leaf the match engine actually resolves against, and it is the level a bug report
    /// should be able to name: league, season, week, game, drive, snap reproduces one play.
    public static func snap(_ parent: UInt64, index: Int) -> UInt64 {
        mix(parent, component(index))
    }

    /// Convenience for the full path, for tests and for reproducing a snap from a bug report.
    ///
    /// Every call is qualified: the parameter names deliberately match the step names, so an
    /// unqualified `league(league)` would resolve to the UUID rather than to the step.
    public static func fullPath(
        league leagueID: UUID,
        year: Int,
        week weekNumber: Int,
        home: UUID,
        away: UUID,
        drive driveIndex: Int,
        snap snapIndex: Int
    ) -> UInt64 {
        var seed = SeedPath.league(leagueID)
        seed = SeedPath.season(seed, year: year)
        seed = SeedPath.week(seed, week: weekNumber)
        seed = SeedPath.game(seed, home: home, away: away)
        seed = SeedPath.drive(seed, index: driveIndex)
        return SeedPath.snap(seed, index: snapIndex)
    }
}
