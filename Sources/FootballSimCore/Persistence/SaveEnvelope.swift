import Foundation
import Compression

public enum SaveEnvelopeError: Error, Equatable {
    case notASaveFile
    case truncatedHeader
    case futureVersion(found: UInt32, supported: UInt32)
    /// An older version with no migration registered. 03b section 4 requires forward-only,
    /// one-step migrations; until that table exists, an older save is refused rather than fed to
    /// the current decoder, which would succeed with wrong data rather than throw.
    case unmigratableVersion(found: UInt32, supported: UInt32)
    /// A header flag this build does not implement. Bit 0 ("body is compressed") is implemented;
    /// every other bit is still reserved, so a file that sets one was written by something newer.
    case unsupportedHeaderFlags(found: UInt8)
    /// A reserved header byte carries data, so the file was written by something this build does
    /// not understand.
    case reservedHeaderBytesSet
    case bodyTooLarge(bytes: Int, maximum: Int)
    case decompressionFailed
}

/// The on-disk wrapper around a save payload.
///
/// 03b section 4 requires the schema version to be readable *without parsing the whole file*. The
/// prior build learned that one the hard way: a save it could not open was a save whose version it
/// could not find out. So the layout puts a fixed 16-byte header in front of the JSON body:
///
///     0..<4    magic, ASCII "PFC1"
///     4..<8    schemaVersion, UInt32 little-endian
///     8        flags — bit 0, "body is compressed", set by every save this build writes
///     9..<16   reserved, always zero
///     16...    body
///
/// Reading the version is a 16-byte read. The flags byte was deliberate headroom, and it has since
/// been spent: compression landed without moving the version field or invalidating a save, because
/// the reader branches on bit 0 and a save written before the flag existed still has it clear.
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
    /// Hard input bound for an offline save. It prevents a damaged or hostile file from allocating
    /// an unbounded buffer before the JSON decoder can reject it. The production size gate is much
    /// lower; this is only the defensive parser ceiling.
    public static let maximumBodyBytes = 512 * 1024 * 1024
    /// Compressed envelopes are the shipped format. Keep their stored input well below the
    /// decompressed ceiling so a hostile file cannot force a half-gigabyte read before zlib gets a
    /// chance to enforce `maximumBodyBytes`. The current season-20 compressed baseline is about
    /// 26 MB; this leaves room for legitimate saves while the production 8 MB target is reduced by
    /// history compaction rather than by silently rejecting valid careers.
    public static let maximumStoredBodyBytes = 64 * 1024 * 1024

    /// What a career is expected to stay inside on disk, and the season-over-season drift allowed
    /// on top of it. Distinct from the two limits above, which are defensive parser ceilings a
    /// hostile file is measured against; these are the product's own bound, and `M1SoakTests` and
    /// `M2SoakTests` assert them at every checkpoint.
    ///
    /// The soaks used to compute the checkpoint sizes and `print` them, which is why the saves grew
    /// past 26 MB at season 20 while `PRODUCT.md` carried the commitment as verified. A number that
    /// is printed is not a gate.
    ///
    /// The drift ratio is the half that matters for a twenty-season career: the retained set is
    /// bounded now, so a late checkpoint may sit above or below an early one as departures cycle,
    /// but it must not climb away from it.
    /// Measured, not chosen: a twenty-season career on the soaks' own seed encodes to 14.76 MB
    /// with departed retention bounded, against 3.67 MB at season 0. The ceiling sits just above
    /// the measurement so a regression trips it; it is not a claim that 16 MB is the target.
    public static let productionSaveByteCeiling = 16 * 1024 * 1024
    /// Season 5 to season 20 measured 1.80x. The allowance catches the unbounded case this
    /// replaced, which was 3.2x over the same span, and it is deliberately not tight: the save
    /// still drifts across a long career, and `docs/STATUS.md` says so rather than this number
    /// pretending otherwise.
    public static let productionSaveDriftRatio = 2.0

    /// Returns the stored-body limit implied by a header. Callers use this after reading only the
    /// fixed header, before materialising the rest of a file. Invalid headers deliberately fall
    /// back to the decompressed limit so the normal envelope validator can report the precise
    /// header error.
    public static func storedBodyLimit(ofHeader header: Data) -> Int {
        guard header.count >= headerLength,
              (try? schemaVersion(ofHeader: header)) == currentSchemaVersion else {
            return maximumBodyBytes
        }
        let bytes = Array(header.prefix(headerLength))
        guard bytes[8] & ~compressedBodyFlag == 0,
              bytes[9..<headerLength].allSatisfy({ $0 == 0 }) else {
            return maximumBodyBytes
        }
        return bytes[8] & compressedBodyFlag == compressedBodyFlag
            ? maximumStoredBodyBytes
            : maximumBodyBytes
    }

    public static func encode<T: Encodable>(_ payload: T) throws -> Data {
        var data = Data(magic)
        withUnsafeBytes(of: currentSchemaVersion.littleEndian) { data.append(contentsOf: $0) }
        data.append(compressedBodyFlag)
        data.append(contentsOf: Array(repeating: UInt8(0), count: 7))   // reserved
        let body = try JSONEncoder.stable().encode(payload)
        guard body.count <= maximumBodyBytes else {
            throw SaveEnvelopeError.bodyTooLarge(
                bytes: body.count,
                maximum: maximumBodyBytes
            )
        }
        let compressed = try (body as NSData).compressed(using: .zlib) as Data
        guard compressed.count <= maximumStoredBodyBytes else {
            throw SaveEnvelopeError.bodyTooLarge(
                bytes: compressed.count,
                maximum: maximumStoredBodyBytes
            )
        }
        data.append(compressed)
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
        try JSONDecoder.stable().decode(type, from: body(from: data))
    }

    /// Returns the validated JSON body without interpreting its application schema. This is the
    /// seam used by the app document migrator to distinguish a legacy bare GameState from the
    /// current document wrapper while keeping the envelope header contract in the engine module.
    public static func body(from data: Data) throws -> Data {
        let version = try schemaVersion(ofHeader: data)
        // Refused, never partially opened: a newer writer may have changed the body's shape, and a
        // half-migrated league is worse than a refused one.
        guard version <= currentSchemaVersion else {
            throw SaveEnvelopeError.futureVersion(found: version, supported: currentSchemaVersion)
        }
        // Envelope migrations are separate from the application document migration. The envelope
        // header remains v1; the document decoder owns root schema 11 → 12 defaults.
        guard version == currentSchemaVersion else {
            throw SaveEnvelopeError.unmigratableVersion(found: version,
                                                        supported: currentSchemaVersion)
        }
        // The writer sets bit 0 and zeroes everything else; a reader that never checks the rest
        // turns the remaining headroom into a promise nothing keeps. A body compressed by some
        // future scheme and handed to JSONDecoder fails as dataCorrupted, which tells the player
        // nothing.
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
        let storedLimit = storedBodyLimit(ofHeader: Data(header))
        guard stored.count <= storedLimit else {
            throw SaveEnvelopeError.bodyTooLarge(bytes: stored.count, maximum: storedLimit)
        }
        let body = header[8] & compressedBodyFlag == 0
            ? Data(stored)
            : try decompress(Data(stored))
        guard body.count <= maximumBodyBytes else {
            throw SaveEnvelopeError.bodyTooLarge(bytes: body.count, maximum: maximumBodyBytes)
        }
        return body
    }

    private static func decompress(_ input: Data) throws -> Data {
        guard !input.isEmpty else { throw SaveEnvelopeError.decompressionFailed }
        let chunkSize = 64 * 1024
        var output = Data()
        var chunk = [UInt8](repeating: 0, count: chunkSize)
        return try input.withUnsafeBytes { source in
            try chunk.withUnsafeMutableBytes { destination in
                guard let sourceBase = source.bindMemory(to: UInt8.self).baseAddress,
                      let destinationBase = destination.bindMemory(to: UInt8.self).baseAddress else {
                    throw SaveEnvelopeError.decompressionFailed
                }
                var stream = compression_stream(
                    dst_ptr: destinationBase,
                    dst_size: chunkSize,
                    src_ptr: sourceBase,
                    src_size: input.count,
                    state: nil
                )
                guard compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
                        != COMPRESSION_STATUS_ERROR else {
                    throw SaveEnvelopeError.decompressionFailed
                }
                defer { compression_stream_destroy(&stream) }
                stream.src_ptr = sourceBase
                stream.src_size = input.count
                while true {
                    stream.dst_ptr = destinationBase
                    stream.dst_size = chunkSize
                    let status = compression_stream_process(&stream, 0)
                    let produced = chunkSize - stream.dst_size
                    if produced > 0 {
                        output.append(contentsOf: UnsafeBufferPointer(
                            start: destinationBase,
                            count: produced
                        ))
                    }
                    guard output.count <= maximumBodyBytes else {
                        throw SaveEnvelopeError.bodyTooLarge(
                            bytes: output.count,
                            maximum: maximumBodyBytes
                        )
                    }
                    if status == COMPRESSION_STATUS_END { return output }
                    if status == COMPRESSION_STATUS_ERROR {
                        throw SaveEnvelopeError.decompressionFailed
                    }
                    if produced == 0 && stream.src_size == 0 {
                        throw SaveEnvelopeError.decompressionFailed
                    }
                }
            }
        }
    }
}
