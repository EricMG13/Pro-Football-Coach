import Foundation

/// What an organisation earns, owes and has built. `02` §10.
///
/// Money existed in exactly two forms — the professional salary cap and the college NIL pot — and
/// neither is a budget: no revenue, no facilities, no wage bill, nothing a coach could spend or run
/// out of outside signing players. Facilities in particular are the standard college-football lever
/// and had no representation at all, so a rich programme and a poor one developed players
/// identically.
///
/// **Optional on the organisation**, so a save written before this exists still decodes and gets the
/// generated default rather than a decoding error. `GameState` requires an exact schema match with
/// no migration path, so an additive optional is the only shape that does not strand every existing
/// save.
public struct OrganisationFinances: Codable, Sendable, Equatable {
    /// How good the buildings are, on the shared 40–99 rating scale. Development reads it.
    public let facilities: Rating
    /// Money on hand that is not the cap and not NIL: what a programme can spend on staff and on
    /// building things.
    public private(set) var reserves: Int

    public init(facilities: Rating, reserves: Int) {
        self.facilities = facilities
        self.reserves = max(0, reserves)
    }

    /// What this organisation takes in over a season, before it spends anything.
    ///
    /// Derived from prestige rather than stored, because revenue *is* a consequence of standing and
    /// a second number would be one more thing to keep in step with it.
    public static func annualRevenue(prestige: Rating, tier: Tier) -> Int {
        let base = tier == .pro ? FinanceRules.proBaseRevenue : FinanceRules.collegeBaseRevenue
        let above = prestige.value - SharedRules.ratingRange.lowerBound
        return base + above * FinanceRules.revenuePerPrestigePoint
    }

    public mutating func credit(_ amount: Int) {
        reserves = max(0, reserves + max(0, amount))
    }

    /// Spends, and says whether it could. A budget that goes negative is a budget nothing enforces.
    public mutating func spend(_ amount: Int) -> Bool {
        guard amount >= 0, reserves >= amount else { return false }
        reserves -= amount
        return true
    }
}

/// Every constant the money model reads. `02` §10.
///
/// **Integer dollars, never floating point** — `CLAUDE.md`'s rule, and the reason the cap is already
/// an `Int`.
public enum FinanceRules {
    /// What a floor-prestige organisation takes in over a season.
    public static let collegeBaseRevenue = 40_000_000
    public static let proBaseRevenue = 300_000_000
    /// What each prestige point above the floor is worth in revenue.
    public static let revenuePerPrestigePoint = 1_400_000

    /// What an organisation starts with in hand: one season's revenue is too much and nothing is
    /// too little, so half a season is the plain choice and it is stated rather than tuned.
    public static let openingReserveShare = 2

    /// A staff salary, from what the market thinks of them.
    ///
    /// Rating-derived like the professional contracts `02` §4.2a generates, and for the same reason:
    /// a wage that ignored ability would make continuity free.
    public static func salary(reputation: Rating, role: StaffRole) -> Int {
        let above = reputation.value - SharedRules.ratingRange.lowerBound
        return role.baseSalary + above * salaryPerReputationPoint
    }

    public static let salaryPerReputationPoint = 22_000

    /// How much a top facility is worth to development, in the same points a development component
    /// carries. Small: buildings help, coaching helps more, and a facility that outweighed a
    /// position coach would make the staff decorative.
    public static let facilityDevelopmentBonus = 1
    /// Facility rating at or above which that bonus applies.
    public static let strongFacilityRating = 80
}

public extension StaffRole {
    /// What this role costs before reputation. A head coach is paid more than a position coach, and
    /// the gap is what makes a staff budget a decision rather than a headcount.
    var baseSalary: Int {
        switch self {
        case .headCoach: return 900_000
        case .offensiveCoordinator, .defensiveCoordinator: return 500_000
        case .specialTeamsCoordinator, .strengthCoordinator: return 260_000
        case .positionCoach: return 180_000
        }
    }
}
