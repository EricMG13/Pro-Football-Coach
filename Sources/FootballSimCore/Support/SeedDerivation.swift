import Foundation

/// Where a derived seed sits in the hierarchy `03-MATCH-ENGINE.md` section 3 clause 6 specifies:
/// league -> season -> week -> game -> drive -> snap.
///
/// The raw value is mixed into the derivation, so a week and a game with the same ordinal under the
/// same parent get different streams. Without it, a game would replay its week's numbers.
public enum SeedScope: UInt64, Sendable, CaseIterable {
    case league = 1
    case season = 2
    case week = 3
    case game = 4
    case drive = 5
    case snap = 6
}

public extension SeededRandom {
    /// Derives a child seed from a parent seed, a scope tag and a sibling ordinal.
    ///
    /// FNV-1a over the little-endian bytes of parent, scope and ordinal, in that order — the same
    /// mixing function and the same constants as `seed(from:)`, so the whole project has one
    /// documented way of turning bytes into a seed. FNV-1a is not a cryptographic hash and does not
    /// need to be: the requirement is reproducibility across processes and good separation between
    /// siblings, and salting is exactly what must not happen here.
    ///
    /// The ordinal is reinterpreted bit-for-bit rather than converted, so a negative ordinal is a
    /// distinct input rather than an aliased or trapping one.
    static func derive(from parent: UInt64, scope: SeedScope, ordinal: Int) -> UInt64 {
        var value = fnvOffsetBasis
        value = mix(value, bytesOf: parent)
        value = mix(value, bytesOf: scope.rawValue)
        value = mix(value, bytesOf: UInt64(bitPattern: Int64(ordinal)))
        return value
    }

    /// Derives a child seed from an identifier rather than an ordinal.
    ///
    /// Uses the UUID's raw bytes. Never `hashValue`, which Swift salts per launch — the bug that
    /// made one save produce a different league every app start.
    ///
    /// This overload feeds sixteen bytes through the accumulator where the ordinal one feeds eight,
    /// so the two cannot alias except by an outright FNV collision. That is not defended against
    /// and does not need to be: no caller chooses between the overloads for the same entity.
    static func derive(from parent: UInt64, scope: SeedScope, identifier: UUID) -> UInt64 {
        var value = fnvOffsetBasis
        value = mix(value, bytesOf: parent)
        value = mix(value, bytesOf: scope.rawValue)
        withUnsafeBytes(of: identifier.uuid) { raw in
            for byte in raw { value = (value ^ UInt64(byte)) &* fnvPrime }
        }
        return value
    }

    private static var fnvOffsetBasis: UInt64 { 0xCBF2_9CE4_8422_2325 }
    private static var fnvPrime: UInt64 { 0x0000_0100_0000_01B3 }

    private static func mix(_ accumulator: UInt64, bytesOf word: UInt64) -> UInt64 {
        var value = accumulator
        withUnsafeBytes(of: word.littleEndian) { raw in
            for byte in raw { value = (value ^ UInt64(byte)) &* fnvPrime }
        }
        return value
    }
}
