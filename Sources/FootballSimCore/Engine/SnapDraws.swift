public struct SnapDraws: Sendable, Equatable {
    public let outcome, yardage, target, attribution, secondary, turnover, spareA, spareB: Double

    public init(rng: inout SeededRandom) {
        outcome = rng.double01(); yardage = rng.double01()
        target = rng.double01(); attribution = rng.double01()
        secondary = rng.double01(); turnover = rng.double01()
        spareA = rng.double01(); spareB = rng.double01()
    }

    public init(
        outcome: Double, yardage: Double, target: Double, attribution: Double,
        secondary: Double, turnover: Double, spareA: Double, spareB: Double
    ) {
        self.outcome = outcome; self.yardage = yardage
        self.target = target; self.attribution = attribution
        self.secondary = secondary; self.turnover = turnover
        self.spareA = spareA; self.spareB = spareB
    }
}
