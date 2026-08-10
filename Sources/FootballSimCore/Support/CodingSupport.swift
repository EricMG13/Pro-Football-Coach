import Foundation

// Swift encodes a dictionary whose key isn't `CodingKeyRepresentable` as a flat
// [key, value, key, value…] array in hash order — which differs run to run. The model is full
// of `[UUID: …]` maps (standings, per-player box scores, dead money), so without this a save
// file's bytes churn between runs and determinism tests can't hold.
//
// Conforming UUID makes those encode as keyed JSON objects, which `.sortedKeys` then orders
// deterministically — and makes save files readable besides.
extension UUID: @retroactive CodingKeyRepresentable {
    public var codingKey: any CodingKey { StringCodingKey(uuidString) }

    public init?<T: CodingKey>(codingKey: T) {
        guard let value = UUID(uuidString: codingKey.stringValue) else { return nil }
        self = value
    }
}

/// Minimal string-backed coding key, needed only by the conformance above.
public struct StringCodingKey: CodingKey {
    public let stringValue: String
    public var intValue: Int? { nil }

    public init(_ stringValue: String) { self.stringValue = stringValue }
    public init?(stringValue: String) { self.stringValue = stringValue }
    public init?(intValue: Int) { nil }
}

// Dates encode as seconds since 1970, not ISO 8601.
//
// `.iso8601` renders whole seconds only, so `decode(encode(x)) != x` for any Date carrying a
// fraction — a silent precision loss on the way *out*, which a byte-stability test cannot see
// because encoding stays perfectly idempotent. Found by an adversarial review of P0.
//
// The engine has no ambient `Date()` at all (03 section 3 clause 5) and time comes from the
// simulated calendar, so a save should rarely carry one. That is a reason to make the strategy
// lossless and stop thinking about it, not a reason to leave a lossy one in place.
public extension JSONEncoder {
    /// The encoder every save and every determinism check uses: stable key order, lossless dates.
    static func stable() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }
}

public extension JSONDecoder {
    static func stable() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
