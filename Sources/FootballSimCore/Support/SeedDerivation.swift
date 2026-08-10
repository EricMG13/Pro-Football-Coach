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
    /// FNV-1a over the little-endian bytes of parent, scope and ordinal, in that order, through the
    /// single `SeededRandom.fnv1a` the whole project shares with `seed(from:)`.
    ///
    /// The ordinal is reinterpreted bit-for-bit rather than converted, so a negative ordinal is a
    /// distinct input rather than an aliased or trapping one.
    static func derive(from parent: UInt64, scope: SeedScope, ordinal: Int) -> UInt64 {
        var value = fnv1a(word: parent, continuing: fnvOffsetBasis)
        value = fnv1a(word: scope.rawValue, continuing: value)
        return fnv1a(word: UInt64(bitPattern: Int64(ordinal)), continuing: value)
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
        var value = fnv1a(word: parent, continuing: fnvOffsetBasis)
        value = fnv1a(word: scope.rawValue, continuing: value)
        return withUnsafeBytes(of: identifier.uuid) { fnv1a($0, continuing: value) }
    }
}
