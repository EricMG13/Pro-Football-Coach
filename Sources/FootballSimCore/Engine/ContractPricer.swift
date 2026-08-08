import Foundation

/// Turns a player into a price. Used at league generation, in re-signing, and by the free-agent
/// market, so every part of the game agrees on what a player is worth.
public enum ContractPricer {

    /// Fraction of the cap a replacement-level starter costs, before position premium.
    private static let baseShareOfCap = 0.0075

    /// Annual salary the open market would pay this player.
    public static func marketSalary(
        overall: Int,
        age: Int,
        position: Position,
        salaryCap: Int = LeagueRules.salaryCapYearOne
    ) -> Int {
        // Value climbs steeply above replacement level — the gap between a 78 and an 88 is
        // worth far more than the gap between a 58 and a 68.
        let quality = max(0.0, Double(overall) - 58.0) / 30.0
        let curve = pow(quality, 2.4)
        let premium = LeagueRules.positionSalaryPremium(position)

        let peak = LeagueRules.peakAgeWindow(position)
        let ageFactor: Double
        if age < peak.lowerBound {
            ageFactor = 0.9 + Double(age - peak.lowerBound) * 0.02
        } else if age > peak.upperBound {
            ageFactor = max(0.45, 1.0 - Double(age - peak.upperBound) * 0.09)
        } else {
            ageFactor = 1.0
        }

        let raw = Double(salaryCap) * baseShareOfCap * curve * premium * ageFactor * 6.0
        let minimum = age >= LeagueRules.veteranMinimumAge
            ? LeagueRules.minimumSalaryVeteran
            : LeagueRules.minimumSalaryYoung
        return max(minimum, roundToNearest(Int(raw), 100_000))
    }

    public static func marketSalary(for player: Player, salaryCap: Int = LeagueRules.salaryCapYearOne) -> Int {
        marketSalary(
            overall: player.overall,
            age: player.age,
            position: player.position,
            salaryCap: salaryCap
        )
    }

    /// What the player will actually accept from a given team, after loyalty, morale and
    /// the franchise's standing are taken into account.
    public static func askingSalary(
        for player: Player,
        teamReputation: Int,
        salaryCap: Int = LeagueRules.salaryCapYearOne
    ) -> Int {
        var multiplier = 1.0
        if player.has(.loyal) { multiplier -= 0.20 }
        if player.has(.mercenary) { multiplier += 0.10 }
        multiplier += Double(60 - player.morale) * 0.002
        multiplier -= Double(teamReputation - 50) * 0.001
        let salary = Double(marketSalary(for: player, salaryCap: salaryCap)) * max(0.6, multiplier)
        return max(LeagueRules.minimumSalaryYoung, roundToNearest(Int(salary), 100_000))
    }

    /// Contract length a player of this profile expects. Prime players want long deals;
    /// older and fringe players take short ones.
    public static func expectedYears(overall: Int, age: Int, _ rng: inout SeededRandom) -> Int {
        switch (overall, age) {
        case let (ovr, years) where ovr >= 80 && years <= 28: rng.int(in: 4...5)
        case let (ovr, years) where ovr >= 74 && years <= 30: rng.int(in: 3...4)
        case let (_, years) where years >= 33: rng.int(in: 1...2)
        case let (ovr, _) where ovr >= 68: rng.int(in: 2...3)
        // Even depth players sign multi-year deals; one-year contracts across the board
        // would push most of the league into free agency every single offseason.
        default: rng.int(in: 2...3)
        }
    }

    /// A full market-rate offer, with the bonus and guarantee structure the tier implies.
    public static func marketContract(
        for player: Player,
        salaryCap: Int = LeagueRules.salaryCapYearOne,
        rng: inout SeededRandom
    ) -> Contract {
        let salary = marketSalary(for: player, salaryCap: salaryCap)
        let years = expectedYears(overall: player.overall, age: player.age, &rng)
        // Better players convert more of the deal into up-front bonus, which is what creates
        // the dead-money trap later.
        let bonusShare = player.overall >= 80 ? 0.35 : (player.overall >= 72 ? 0.22 : 0.10)
        let totalBase = salary * years
        let signingBonus = roundToNearest(Int(Double(totalBase) * bonusShare), 100_000)
        let perYear = max(
            LeagueRules.minimumSalaryYoung,
            (totalBase - signingBonus) / years
        )
        let guaranteed = player.overall >= 80 ? min(years, 2) : (player.overall >= 72 ? 1 : 0)
        return Contract(
            years: years,
            salaryPerYear: Array(repeating: perYear, count: years),
            signingBonus: signingBonus,
            guaranteedYears: guaranteed
        )
    }

    /// Slotted rookie deal: four years, value falling smoothly across the draft.
    public static func rookieContract(round: Int, pickInRound: Int) -> Contract {
        let overallPick = max(1, (round - 1) * LeagueRules.teamCount + pickInRound)
        let top = 9_500_000.0
        let bottom = 900_000.0
        let progress = Double(overallPick - 1) / Double(LeagueRules.draftPickCount - 1)
        // Exponential decay: the first few picks are worth far more than the slope suggests.
        let annual = bottom + (top - bottom) * pow(1 - progress, 2.6)
        let salary = max(LeagueRules.minimumSalaryYoung, roundToNearest(Int(annual), 50_000))
        let years = 4
        let bonusShare = 0.30
        let signingBonus = roundToNearest(Int(Double(salary * years) * bonusShare), 50_000)
        let perYear = max(
            LeagueRules.minimumSalaryYoung,
            (salary * years - signingBonus) / years
        )
        return Contract(
            years: years,
            salaryPerYear: Array(repeating: perYear, count: years),
            signingBonus: signingBonus,
            guaranteedYears: round == 1 ? 3 : (round == 2 ? 1 : 0),
            isRookieDeal: true
        )
    }

    /// League-minimum one-year deal, used for practice squad, UDFA and street free agents.
    public static func minimumContract(age: Int, years: Int = 1) -> Contract {
        let salary = age >= LeagueRules.veteranMinimumAge
            ? LeagueRules.minimumSalaryVeteran
            : LeagueRules.minimumSalaryYoung
        return Contract.flat(years: years, salary: salary)
    }

    private static func roundToNearest(_ value: Int, _ step: Int) -> Int {
        guard step > 0 else { return value }
        return ((value + step / 2) / step) * step
    }
}
