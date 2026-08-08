import Foundation

/// A player contract, with the cap consequences that make roster building hard.
///
/// The signing bonus is paid up front but charged against the cap evenly across the deal.
/// Cut a player early and every unpaid proration slams into the current year as dead money —
/// that is the trap the whole front-office game is built around.
public struct Contract: Codable, Sendable, Equatable {
    /// Total length in years.
    public let years: Int
    /// Base salary for each contract year, index 0 being the first.
    public let salaryPerYear: [Int]
    public let signingBonus: Int
    /// How many years of base salary are guaranteed, counted from the start of the deal.
    public let guaranteedYears: Int
    /// Years already played. Equals `years` when the deal expires.
    public var yearsElapsed: Int
    public let isRookieDeal: Bool

    public init(
        years: Int,
        salaryPerYear: [Int],
        signingBonus: Int = 0,
        guaranteedYears: Int = 0,
        yearsElapsed: Int = 0,
        isRookieDeal: Bool = false
    ) {
        precondition(years > 0, "a contract needs at least one year")
        precondition(salaryPerYear.count == years, "salary array must cover every contract year")
        self.years = years
        self.salaryPerYear = salaryPerYear
        self.signingBonus = signingBonus
        self.guaranteedYears = Swift.min(guaranteedYears, years)
        self.yearsElapsed = yearsElapsed
        self.isRookieDeal = isRookieDeal
    }

    /// Convenience for a flat deal with no bonus.
    public static func flat(years: Int, salary: Int, guaranteedYears: Int = 0) -> Contract {
        Contract(
            years: years,
            salaryPerYear: Array(repeating: salary, count: years),
            guaranteedYears: guaranteedYears
        )
    }

    /// Bonus years are capped at five even on longer deals, matching real proration limits.
    public var prorationYears: Int { Swift.min(years, LeagueRules.maxBonusProrationYears) }

    /// Even share of the signing bonus charged each proration year. Integer division; the
    /// remainder is absorbed by year zero so the parts always sum to the whole.
    public var bonusProrationPerYear: Int { signingBonus / prorationYears }

    private var prorationRemainder: Int { signingBonus - bonusProrationPerYear * prorationYears }

    /// Proration charged in a specific contract year (0-based).
    public func bonusProration(inYear year: Int) -> Int {
        guard year >= 0, year < prorationYears else { return 0 }
        return bonusProrationPerYear + (year == 0 ? prorationRemainder : 0)
    }

    /// Salary plus bonus proration for a contract year (0-based).
    public func capHit(inYear year: Int) -> Int {
        guard year >= 0, year < years else { return 0 }
        return salaryPerYear[year] + bonusProration(inYear: year)
    }

    public var currentCapHit: Int { capHit(inYear: yearsElapsed) }

    public var yearsRemaining: Int { Swift.max(0, years - yearsElapsed) }

    public var isExpiring: Bool { yearsRemaining <= 1 }

    public var isExpired: Bool { yearsRemaining == 0 }

    public var totalValue: Int { salaryPerYear.reduce(0, +) + signingBonus }

    public var averagePerYear: Int { totalValue / years }

    /// Cost of cutting the player right now: all unamortised bonus accelerates into this year,
    /// plus any remaining guaranteed base salary.
    public func deadMoneyIfCutNow() -> Int {
        guard yearsElapsed < years else { return 0 }
        var dead = 0
        for year in yearsElapsed..<prorationYears { dead += bonusProration(inYear: year) }
        for year in yearsElapsed..<guaranteedYears { dead += salaryPerYear[year] }
        return dead
    }

    /// Cap space freed by cutting: this year's hit minus the dead money it triggers.
    /// Frequently negative, which is exactly why cap hell is hard to escape.
    public func capSavingsIfCutNow() -> Int {
        currentCapHit - deadMoneyIfCutNow()
    }

    /// Advances the deal one league year.
    public func aged() -> Contract {
        var next = self
        next.yearsElapsed += 1
        return next
    }
}
