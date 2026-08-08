import Foundation

/// Deterministic pseudo-random source. Every engine entry point threads one of these so a
/// given seed always reproduces the same season — bugs are reproducible and tests are exact.
///
/// SplitMix64: fast, tiny state, good statistical quality, trivially serializable (the
/// whole generator is one `UInt64`, so a save file can resume the exact stream).
public struct SeededRandom: Codable, Sendable, Equatable {
    private var state: UInt64

    /// A seed derived from identifiers rather than from `hashValue`.
    ///
    /// `UUID.hashValue` is salted with a per-process random seed, so anything derived from it
    /// changes between launches. Using it to seed a generator makes the league unreproducible
    /// from its own seed, which is the one guarantee this type exists to provide.
    public static func seed(from identifiers: UUID...) -> UInt64 {
        var value: UInt64 = 0xCBF2_9CE4_8422_2325
        for identifier in identifiers {
            withUnsafeBytes(of: identifier.uuid) { bytes in
                for byte in bytes {
                    value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
                }
            }
        }
        return value
    }

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in `[0, 1)`, using the top 53 bits (full `Double` mantissa precision).
    public mutating func double01() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// Uniform integer in `range`. Uses rejection sampling so wide ranges stay unbiased.
    public mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound) + 1
        guard span > 1 else { return range.lowerBound }
        // Discard the tail that would wrap unevenly across `span` buckets.
        let limit = UInt64.max - (UInt64.max % span) - 1
        var draw = next()
        while draw > limit { draw = next() }
        return range.lowerBound + Int(draw % span)
    }

    public mutating func chance(_ probability: Double) -> Bool {
        if probability <= 0 { return false }
        if probability >= 1 { return true }
        return double01() < probability
    }

    public mutating func pick<T>(_ elements: [T]) -> T {
        precondition(!elements.isEmpty, "pick requires a non-empty array")
        return elements[int(in: 0...(elements.count - 1))]
    }

    /// Fisher-Yates, seeded — the stdlib's `shuffled()` uses system randomness and would
    /// break determinism.
    public mutating func shuffled<T>(_ elements: [T]) -> [T] {
        var result = elements
        guard result.count > 1 else { return result }
        for index in stride(from: result.count - 1, to: 0, by: -1) {
            result.swapAt(index, int(in: 0...index))
        }
        return result
    }

    /// A UUID drawn from the seeded stream. Entity identities have to come from here rather
    /// than `UUID()`, or two runs of the same seed produce leagues that differ only by id —
    /// which breaks save comparison and every determinism guarantee built on it.
    public mutating func uuid() -> UUID {
        let high = next()
        let low = next()
        var bytes = [UInt8]()
        bytes.reserveCapacity(16)
        for shift in stride(from: 56, through: 0, by: -8) { bytes.append(UInt8((high >> UInt64(shift)) & 0xFF)) }
        for shift in stride(from: 56, through: 0, by: -8) { bytes.append(UInt8((low >> UInt64(shift)) & 0xFF)) }
        // Stamp version 4 / RFC-4122 variant bits so these read as ordinary random UUIDs.
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    /// Box-Muller transform. Sim outcomes are built from these: most plays land near the
    /// mean, with the tails supplying the occasional explosive play or disaster.
    public mutating func gaussian(mean: Double, sd: Double) -> Double {
        let u1 = Swift.max(double01(), .leastNonzeroMagnitude)
        let u2 = double01()
        return mean + sd * (-2 * Foundation.log(u1)).squareRoot() * Foundation.cos(2 * .pi * u2)
    }

    /// Gaussian truncated to `range` by resampling — keeps ratings inside legal bounds
    /// without the pile-up at the edges that clamping produces.
    public mutating func gaussian(mean: Double, sd: Double, in range: ClosedRange<Double>) -> Double {
        for _ in 0..<16 {
            let value = gaussian(mean: mean, sd: sd)
            if range.contains(value) { return value }
        }
        return Swift.min(Swift.max(mean, range.lowerBound), range.upperBound)
    }
}
