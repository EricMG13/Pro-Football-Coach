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

public extension JSONEncoder {
    /// The encoder every save and every determinism check uses: stable key order, ISO dates.
    static func stable() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

public extension JSONDecoder {
    static func stable() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
