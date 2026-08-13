import Foundation

/// Numbers a roster, per `02` §4.1a.
///
/// Derived rather than stored, because uniqueness is a *team's* invariant and a player changes
/// teams. A stored number would have to be reassigned and de-conflicted on every transfer, draft
/// pick, signing and walk-on, and any path that forgot would put two of the same number on one
/// roster with nothing to catch it. Assigning over the roster makes uniqueness hold by construction
/// and leaves no path to forget.
public enum JerseyNumbers {
    /// The number each player wears, unique **within their unit**.
    ///
    /// Per unit rather than per roster, because what a number distinguishes is two players who
    /// could be on the field together — and because a roster-wide rule cannot be satisfied at all:
    /// `CollegeRules.rosterLimit` is 105 against a hundred legal numbers.
    ///
    /// Deterministic across processes and launches: the preferred number comes from the player's
    /// identifier *bytes*, never from a salted hash, which is `03` §3 clause 2's rule for seeds and
    /// applies here for the same reason — a per-launch hash would renumber the squad every time the
    /// app opened.
    ///
    /// Order of assignment is by identifier, so the result depends on the *set* of players and not
    /// on the order they arrive in.
    public static func assign(_ players: [Player]) -> [UUID: Int] {
        var numbers: [UUID: Int] = [:]
        var takenByUnit: [Unit: Set<Int>] = [:]
        numbers.reserveCapacity(players.count)
        for player in players.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            let unit = player.position.unit
            let number = firstFree(
                from: preferred(for: player),
                in: band(for: player),
                taken: takenByUnit[unit] ?? []
            )
            numbers[player.id] = number
            takenByUnit[unit, default: []].insert(number)
        }
        return numbers
    }

    /// The number this player would wear on an empty roster.
    public static func preferred(for player: Player) -> Int {
        let band = band(for: player)
        let width = band.upperBound - band.lowerBound + 1
        let draw = withUnsafeBytes(of: player.id.uuid) {
            SeededRandom.fnv1a($0, continuing: SeededRandom.fnvOffsetBasis)
        }
        return band.lowerBound + Int(draw % UInt64(width))
    }

    public static func band(for player: Player) -> ClosedRange<Int> {
        SharedRules.jerseyBandByPosition[player.position] ?? SharedRules.jerseyNumberRange
    }

    /// The first free number at or after `preferred`, wrapping inside the band and then spilling
    /// into the general range.
    ///
    /// The spill is what makes the function total. A band is narrower than a roster's need at some
    /// positions — a college roster carries far more than ten offensive linemen — so without it a
    /// roster would run out and some player would have no number at all.
    ///
    /// The band is passed in rather than inferred from the number. Inferring it meant searching the
    /// rules table for a range containing the value, which is only well-defined while no two bands
    /// partially overlap — true today, and a trap for whoever widens one.
    private static func firstFree(
        from preferred: Int,
        in band: ClosedRange<Int>,
        taken: Set<Int>
    ) -> Int {
        let width = band.upperBound - band.lowerBound + 1
        for step in 0..<width {
            let candidate = band.lowerBound + (preferred - band.lowerBound + step) % width
            if !taken.contains(candidate) { return candidate }
        }
        for candidate in SharedRules.jerseyNumberRange where !taken.contains(candidate) {
            return candidate
        }
        // Unreachable while a roster is smaller than the hundred legal numbers, which every roster
        // limit in the rules guarantees. Returning the preferred number rather than trapping keeps
        // a read model from crashing a screen if that ever stops being true.
        return preferred
    }
}
