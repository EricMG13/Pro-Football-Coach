import Foundation

public enum SaveEnvelopeError: Error, Equatable {
    case notASaveFile
    case truncatedHeader
    case futureVersion(found: UInt32, supported: UInt32)
    /// An older version with no migration registered. 03b section 4 requires forward-only,
    /// one-step migrations; until that table exists, an older save is refused rather than fed to
    /// the current decoder, which would succeed with wrong data rather than throw.
    case unmigratableVersion(found: UInt32, supported: UInt32)
    /// A header flag this build does not implement — today, the reserved "body is compressed" bit.
    case unsupportedHeaderFlags(found: UInt8)
    /// A reserved header byte carries data, so the file was written by something this build does
    /// not understand.
    case reservedHeaderBytesSet
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

    /// Flags bit 0: the body is zlib-compressed.
    ///
    /// The bit the header reserved from the start. FSC-003 made it urgent rather than theoretical:
    /// the 30-season gate measured **306.9 MB** of uncompressed JSON, against an 8 MB production
    /// ceiling, and a league snapshot is the most compressible thing in the build — thousands of
    /// near-identical records with repeated keys.
    private static let compressedBodyFlag: UInt8 = 1

    public static func encode<T: Encodable>(_ payload: T) throws -> Data {
        var data = Data(magic)
        withUnsafeBytes(of: currentSchemaVersion.littleEndian) { data.append(contentsOf: $0) }
        data.append(compressedBodyFlag)
        data.append(contentsOf: Array(repeating: UInt8(0), count: 7))   // reserved
        let body = try JSONEncoder.stable().encode(payload)
        data.append(try (body as NSData).compressed(using: .zlib) as Data)
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
        // And an *older* version is refused too, rather than handed to the current decoder. There is
        // no migration table yet; 03b section 4 says migrations are forward-only and one step each,
        // and its own "unknown-field defaults" policy means a stale body can decode *successfully*
        // with wrong data instead of throwing. The phase that adds persistence proper adds the
        // table and routes through it here.
        guard version == currentSchemaVersion else {
            throw SaveEnvelopeError.unmigratableVersion(found: version,
                                                        supported: currentSchemaVersion)
        }
        // The writer zeroes the flags and reserved bytes; a reader that never checks them turns
        // "headroom for gzip" into a promise nothing keeps. A compressed body handed to JSONDecoder
        // fails as dataCorrupted, which tells the player nothing.
        let header = Array(data.prefix(headerLength))
        guard header[8] & ~compressedBodyFlag == 0 else {
            throw SaveEnvelopeError.unsupportedHeaderFlags(found: header[8])
        }
        guard header[9..<16].allSatisfy({ $0 == 0 }) else {
            throw SaveEnvelopeError.reservedHeaderBytesSet
        }
        // A save written before the flag existed carries an uncompressed body, which is exactly the
        // compatibility the flag was reserved to provide: the reader branches, the header layout
        // does not move, and no existing save is invalidated.
        let stored = data.dropFirst(headerLength)
        let body = header[8] & compressedBodyFlag == 0
            ? Data(stored)
            : try (Data(stored) as NSData).decompressed(using: .zlib) as Data
        return try JSONDecoder.stable().decode(type, from: body)
    }
}
