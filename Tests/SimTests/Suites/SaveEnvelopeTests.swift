import Foundation
import FootballSimCore

private struct Payload: Codable, Equatable {
    let league: UUID
    let seasons: Int
}

func runSaveEnvelopeTests() {
    suite("Save envelope") {
        let payload = Payload(league: UUID(uuidString: "00000000-0000-4000-8000-0000000000AA")!,
                              seasons: 3)

        test("a payload round-trips") {
            let data = try SaveEnvelope.encode(payload)
            let restored = try SaveEnvelope.decode(Payload.self, from: data)
            expectEqual(restored, payload)
        }

        test("the version is readable from the header alone") {
            // This is the requirement 03b section 4 states: readable WITHOUT parsing the whole file.
            // Handing the reader only the first 16 bytes is how the test proves it, because a
            // reader that needed the body would throw on a truncated one.
            let data = try SaveEnvelope.encode(payload)
            let header = data.prefix(SaveEnvelope.headerLength)
            expectEqual(header.count, 16, "header should be a fixed 16 bytes")
            expectEqual(try SaveEnvelope.schemaVersion(ofHeader: Data(header)),
                        SaveEnvelope.currentSchemaVersion)
        }

        test("a file that is not a save is refused by magic, not by a decode failure") {
            let junk = Data("this is not a save file at all, it is prose".utf8)
            do {
                _ = try SaveEnvelope.schemaVersion(ofHeader: junk)
                expect(false, "junk was accepted as a save header")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .notASaveFile)
            }
        }

        test("a truncated header is refused rather than read past") {
            let data = try SaveEnvelope.encode(payload)
            do {
                _ = try SaveEnvelope.schemaVersion(ofHeader: data.prefix(6))
                expect(false, "a 6-byte header was accepted")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .truncatedHeader)
            }
        }

        test("a header exactly one byte short is refused") {
            // The boundary, because >= is the kind of comparison that gets written as > once.
            let data = try SaveEnvelope.encode(payload)
            do {
                _ = try SaveEnvelope.schemaVersion(ofHeader: data.prefix(SaveEnvelope.headerLength - 1))
                expect(false, "a 15-byte header was accepted")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .truncatedHeader)
            }
        }

        test("a save from a future version is refused, never partially opened") {
            var data = try SaveEnvelope.encode(payload)
            let future = SaveEnvelope.currentSchemaVersion + 1
            withUnsafeBytes(of: future.littleEndian) { raw in
                for (offset, byte) in raw.enumerated() { data[4 + offset] = byte }
            }
            do {
                _ = try SaveEnvelope.decode(Payload.self, from: data)
                expect(false, "a future-version save was opened")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .futureVersion(found: future,
                                                  supported: SaveEnvelope.currentSchemaVersion))
            }
        }

        test("the version field is read little-endian, not byte-reversed") {
            // Pins the byte order rather than only asserting round-trip, which would pass just as
            // happily if reader and writer were both wrong in the same direction.
            var data = try SaveEnvelope.encode(payload)
            data[4] = 0x01; data[5] = 0x02; data[6] = 0x03; data[7] = 0x04
            expectEqual(try SaveEnvelope.schemaVersion(ofHeader: data), 0x0403_0201)
        }

        test("a slice whose indices do not start at zero is read correctly") {
            // Data slices keep their parent's indices. A reader written with bytes[0..<4] against a
            // sliced Data reads the wrong bytes or traps, and a file read in chunks produces
            // exactly such a slice.
            let data = try SaveEnvelope.encode(payload)
            let padded = Data([0xFF, 0xFF, 0xFF]) + data
            let slice = padded.dropFirst(3)
            expect(slice.startIndex == 3, "the fixture did not produce an offset slice")
            expectEqual(try SaveEnvelope.schemaVersion(ofHeader: slice),
                        SaveEnvelope.currentSchemaVersion)
            expectEqual(try SaveEnvelope.decode(Payload.self, from: slice), payload)
        }

        test("encoding is byte-stable across calls") {
            // CodingSupport exists so [UUID: ...] maps encode in a stable order. If that regresses,
            // no byte-level determinism test downstream can hold, so it is asserted here at the
            // layer that depends on it.
            let first = try SaveEnvelope.encode(payload)
            let second = try SaveEnvelope.encode(payload)
            expectEqual(first, second, "the same payload produced two different byte sequences")
        }

        test("a UUID-keyed map encodes in a stable order") {
            // The specific reason CodingSupport is ported. Dictionary iteration order is not
            // stable across processes, so this is the assertion that the conformance is doing its
            // job rather than the map happening to be small.
            struct Mapped: Codable, Equatable { let byTeam: [UUID: Int] }
            var map: [UUID: Int] = [:]
            for index in 0..<32 {
                map[UUID(uuidString: String(format: "00000000-0000-4000-8000-%012X", index))!] = index
            }
            let mapped = Mapped(byTeam: map)
            let first = try SaveEnvelope.encode(mapped)
            let second = try SaveEnvelope.encode(mapped)
            expectEqual(first, second, "a UUID-keyed map produced two different byte sequences")
            expectEqual(try SaveEnvelope.decode(Mapped.self, from: first), mapped)
        }

        test("the magic bytes are the documented ASCII, not whatever the writer felt like") {
            let data = try SaveEnvelope.encode(payload)
            expectEqual(String(decoding: data.prefix(4), as: UTF8.self), "PFC1")
        }

        test("the reserved header bytes are zero, so a later flag cannot read as set") {
            let data = try SaveEnvelope.encode(payload)
            let reserved = Array(data[9..<16])
            expectEqual(reserved, Array(repeating: UInt8(0), count: 7))
        }
    }
}
