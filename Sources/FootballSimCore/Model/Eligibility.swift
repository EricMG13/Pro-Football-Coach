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
        precondition(
            Self.hasSupportedCounters(
                seasonsRemaining: seasonsRemaining,
                yearsRemaining: yearsRemaining
            ),
            "Eligibility counters must remain inside the four-season, five-year clock."
        )
        self.seasonsRemaining = seasonsRemaining
        self.yearsRemaining = yearsRemaining
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeasons = try container.decode(Int.self, forKey: .seasonsRemaining)
        let decodedYears = try container.decode(Int.self, forKey: .yearsRemaining)
        guard Self.hasSupportedCounters(
            seasonsRemaining: decodedSeasons,
            yearsRemaining: decodedYears
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .yearsRemaining,
                in: container,
                debugDescription: "Eligibility counters exceed the supported competition clock."
            )
        }
        seasonsRemaining = decodedSeasons
        yearsRemaining = decodedYears
    }

    /// Exhausted when *either* counter runs out. Checking only the seasons is how a twice-redshirted
    /// player keeps playing past the window that was supposed to close on them.
    public var isExhausted: Bool { seasonsRemaining <= 0 || yearsRemaining <= 0 }

    /// Stable active college state can contain either the original spare clock year or a clock
    /// whose one redshirt has already been spent. A larger or inverted gap can only come from an
    /// unsupported transition or hostile persistence.
    var isValidForActiveCollegeRoot: Bool {
        yearsRemaining >= seasonsRemaining
            && yearsRemaining - seasonsRemaining
                <= CollegeRules.eligibilityClockYears - CollegeRules.seasonsOfCompetition
    }

    /// One year passes. A redshirt year spends the clock without spending a season.
    public func advanced(redshirting: Bool) -> Eligibility {
        Eligibility(
            seasonsRemaining: redshirting
                ? seasonsRemaining
                : Swift.max(0, seasonsRemaining - 1),
            yearsRemaining: Swift.max(0, yearsRemaining - 1)
        )
    }

    private static func hasSupportedCounters(
        seasonsRemaining: Int,
        yearsRemaining: Int
    ) -> Bool {
        (0...CollegeRules.seasonsOfCompetition).contains(seasonsRemaining)
            && (0...CollegeRules.eligibilityClockYears).contains(yearsRemaining)
    }
}
