import Foundation

/// A pro contract. Integer dollars throughout, per `CLAUDE.md`.
///
/// The only arithmetic here is proration and dead money, and both are written so that **no dollar
/// is ever lost or invented**. That is not tidiness: `docs/PORT-LOG.md` records "dead money erased
/// by release" as one of the cap-laundering attacks the prior build's defences had to catch, and a
/// bonus that divides unevenly is the same hole opened by rounding instead of by intent. P8 builds
/// the cap on top of this; if the arithmetic leaks here, every defence it builds leaks with it.
public struct Contract: Codable, Sendable, Equatable {
    /// The contract's length in years. Always equal to `baseSalaryByYear.count`.
    public let years: Int

    /// Base salary for each year of the deal, in dollars.
    public let baseSalaryByYear: [Int]

    /// Paid up front, charged against the cap over `prorationYears`.
    public let signingBonus: Int

    /// `years` and the salary array are reconciled rather than trusted to agree — a save that
    /// disagreed with itself would otherwise trap on load. A short array is padded with zero, a
    /// long one is truncated.
    public init(years: Int, baseSalaryByYear: [Int], signingBonus: Int) {
        let length = Swift.max(0, years)
        var salaries = Array(baseSalaryByYear.prefix(length))
        salaries.append(contentsOf: Array(repeating: 0, count: length - salaries.count))
        self.years = length
        self.baseSalaryByYear = salaries
        self.signingBonus = Swift.max(0, signingBonus)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            years: try container.decode(Int.self, forKey: .years),
            baseSalaryByYear: try container.decode([Int].self, forKey: .baseSalaryByYear),
            signingBonus: try container.decode(Int.self, forKey: .signingBonus)
        )
    }

    /// The bonus spreads over the contract's length, to `ProRules.maximumProrationYears`.
    public var prorationYears: Int { Swift.min(years, ProRules.maximumProrationYears) }

    /// The first year's bonus charge.
    ///
    /// Where the bonus does not divide evenly, later years are one dollar lower — see
    /// `bonusProration(inYear:)`. Use that for anything that sums; this is the headline figure.
    public var annualBonusProration: Int { bonusProration(inYear: 0) }

    /// The bonus charged against the cap in `year`.
    ///
    /// The remainder is distributed one dollar at a time across the earliest years rather than
    /// truncated away. Truncating and summing charges the cap less than the team actually paid,
    /// which is a laundering hole rather than a rounding nit.
    public func bonusProration(inYear year: Int) -> Int {
        guard prorationYears > 0, year >= 0, year < prorationYears else { return 0 }
        let share = signingBonus / prorationYears
        let remainder = signingBonus % prorationYears
        return share + (year < remainder ? 1 : 0)
    }

    /// Base salary plus this year's bonus proration.
    public func capHit(inYear year: Int) -> Int {
        guard year >= 0, year < years else { return 0 }
        return baseSalaryByYear[year] + bonusProration(inYear: year)
    }

    /// Every bonus dollar not yet charged, accelerated into the year of release.
    ///
    /// `charged(before: n) + deadMoney(ifReleasedBeforeYear: n) == signingBonus`, for every `n`. The
    /// invariant is asserted at every release point in `ModelTests`, because "the money has to land
    /// somewhere" is exactly the property a released contract is used to violate.
    public func deadMoney(ifReleasedBeforeYear year: Int) -> Int {
        let alreadyCharged = (0..<Swift.max(0, year)).reduce(0) { $0 + bonusProration(inYear: $1) }
        return signingBonus - alreadyCharged
    }

    /// Every base dollar plus the bonus. What the deal is worth to the player.
    public var totalValue: Int { baseSalaryByYear.reduce(0, +) + signingBonus }
}
