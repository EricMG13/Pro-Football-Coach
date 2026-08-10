public struct WeightedOutcome<Value: Sendable>: Sendable {
    public let entries: [(value: Value, weight: Double)]

    public init(_ entries: [(Value, Double)]) {
        self.entries = entries.map { (value: $0.0, weight: $0.1) }
    }

    public func sample(roll: Double) -> Value? {
        guard roll.isFinite, !entries.isEmpty else { return nil }

        var total = 0.0
        for entry in entries {
            let weight = entry.weight
            guard weight.isFinite, weight >= 0 else { return nil }
            total += weight
        }
        guard total.isFinite, total > 0 else { return nil }

        let bounded = Swift.min(Swift.max(roll, 0), Double(1).nextDown)
        let target = bounded * total
        var cumulative = 0.0
        var lastPositive: Value?
        for entry in entries where entry.weight > 0 {
            lastPositive = entry.value
            cumulative += entry.weight
            if target < cumulative { return entry.value }
        }
        return lastPositive
    }
}

public enum OutcomeSampling {
    public static func integer(in range: ClosedRange<Int>, roll: Double) -> Int? {
        guard roll.isFinite else { return nil }
        let terminalRoll = Double(1).nextDown
        let bounded = Swift.min(Swift.max(roll, 0), terminalRoll)
        let (width, widthOverflow) = range.upperBound.subtractingReportingOverflow(range.lowerBound)
        let (count, countOverflow) = width.addingReportingOverflow(1)
        guard !widthOverflow, !countOverflow, count > 0 else { return nil }
        if bounded == terminalRoll { return range.upperBound }
        let offset = Swift.min(Int(bounded * Double(count)), count - 1)
        let (value, valueOverflow) = range.lowerBound.addingReportingOverflow(offset)
        return valueOverflow ? nil : value
    }
}
