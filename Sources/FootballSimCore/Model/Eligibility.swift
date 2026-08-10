import Foundation

/// A college player's eligibility clock, from `02-GAME-DESIGN.md` section 11.1.
///
/// Two counters, not one. Four seasons of competition sit inside a five-year window, and the extra
/// year is the redshirt — spending it is `02` section 4.1's redshirt decision. A model that tracked
/// only seasons would let a player redshirt indefinitely; one that tracked only years would make
/// the redshirt free.
public struct Eligibility: Codable, Sendable, Equatable {
    public private(set) var seasonsRemaining: Int
    public private(set) var yearsRemaining: Int

    public init(
        seasonsRemaining: Int = CollegeRules.seasonsOfCompetition,
        yearsRemaining: Int = CollegeRules.eligibilityClockYears
    ) {
        self.seasonsRemaining = Swift.max(0, seasonsRemaining)
        self.yearsRemaining = Swift.max(0, yearsRemaining)
    }

    /// Exhausted when *either* counter runs out. Checking only the seasons is how a twice-redshirted
    /// player keeps playing past the window that was supposed to close on them.
    public var isExhausted: Bool { seasonsRemaining <= 0 || yearsRemaining <= 0 }

    /// One year passes. A redshirt year spends the clock without spending a season.
    public func advanced(redshirting: Bool) -> Eligibility {
        Eligibility(
            seasonsRemaining: redshirting ? seasonsRemaining : seasonsRemaining - 1,
            yearsRemaining: yearsRemaining - 1
        )
    }
}
