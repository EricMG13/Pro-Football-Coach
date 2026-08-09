import Foundation

public enum SaveEnvelopeError: Error, Equatable {
    case notASaveFile
    case truncatedHeader
    case futureVersion(found: UInt32, supported: UInt32)
}

/// The on-disk wrapper around a save payload.
///
/// 03b section 4 requires the schema version to be readable *without parsing the whole file*. The
/// prior build learned that one the hard way: a save it could not open was a save whose version it
/// could not find out. So the layout puts a fixed 16-byte header in front of the JSON body:
///
///     0..<4    magic, ASCII "PFC1"
///     4..<8    schemaVersion, UInt32 little-endian
///     8        flags — bit 0 reserved for "body is compressed", currently always 0
///     9..<16   reserved, always zero
///     16...    body
///
/// Reading the version is a 16-byte read. The flags byte is deliberate headroom: 03b section 4 wants
/// the body gzipped, and adding that later must not move the version field or invalidate a save.
public struct SaveEnvelope: Sendable {
    public static let currentSchemaVersion: UInt32 = 1
    public static let headerLength = 16

    private static let magic: [UInt8] = Array("PFC1".utf8)

    public static func encode<T: Encodable>(_ payload: T) throws -> Data {
        var data = Data(magic)
        withUnsafeBytes(of: currentSchemaVersion.littleEndian) { data.append(contentsOf: $0) }
        data.append(0)                                                  // flags: body uncompressed
        data.append(contentsOf: Array(repeating: UInt8(0), count: 7))   // reserved
        data.append(try JSONEncoder.stable().encode(payload))
        return data
    }

    /// Reads the version from the header alone. Accepts any `Data` at least `headerLength` long, so
    /// a caller can pass the first 16 bytes of a file it has not otherwise read.
    ///
    /// Copies into an `Array` first rather than subscripting the `Data`: a `Data` slice keeps its
    /// parent's indices, so `data[0..<4]` on a slice read from the middle of a file reads the wrong
    /// bytes or traps outright. `Array(_:)` reindexes from zero.
    public static func schemaVersion(ofHeader header: Data) throws -> UInt32 {
        guard header.count >= headerLength else { throw SaveEnvelopeError.truncatedHeader }
        let bytes = Array(header.prefix(headerLength))
        guard Array(bytes[0..<4]) == magic else { throw SaveEnvelopeError.notASaveFile }
        return bytes[4..<8].reversed().reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let version = try schemaVersion(ofHeader: data)
        // Refused, never partially opened: a newer writer may have changed the body's shape, and a
        // half-migrated league is worse than a refused one.
        guard version <= currentSchemaVersion else {
            throw SaveEnvelopeError.futureVersion(found: version, supported: currentSchemaVersion)
        }
        return try JSONDecoder.stable().decode(type, from: data.dropFirst(headerLength))
    }
}
