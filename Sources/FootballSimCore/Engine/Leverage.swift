import Foundation

/// Stage 2 of `03-MATCH-ENGINE.md` §1.1: one matchup, scored to a scalar in [-1, 1].
///
///     leverage = f(attackerRating, defenderRating, schemeFit, fatigue, situationModifier) + noise
///
/// Positive favours the attacker. The rating term is a **logistic** on the difference, not a linear
/// one, so a 10-point gap matters more in the middle of the scale than at the ends — `03` §1.1 says
/// so explicitly, and `LeverageTests` asserts the *shape* of the curve rather than only its range,
/// because a linear ramp satisfies the range and fails the requirement.
public enum Leverage {
    /// Scores one matchup.
    ///
    /// `rng` is threaded explicitly and consumed exactly once, whatever the inputs. A resolver whose
    /// draw count depended on the ratings would couple the stream to the roster — the defect that
    /// made P2's archetype sampling non-uniform — and would make a replay diverge the moment a
    /// player's rating changed.
    public static func score(
        attacker: Rating,
        defender: Rating,
        schemeFit: Double = 0,
        attackerFatigue: Double = 0,
        defenderFatigue: Double = 0,
        situationModifier: Double = 0,
        rng: inout SeededRandom
    ) -> Double {
        let base = logistic(Double(attacker.value - defender.value))
        let fit = clampUnit(schemeFit) * MatchupRules.schemeFitWeight
        let fatigue = (clampUnit(defenderFatigue) - clampUnit(attackerFatigue))
            * MatchupRules.fatigueWeight
        let noise = rng.gaussian(mean: 0, sd: MatchupRules.leverageNoise)
        return clamp(base + fit + fatigue + situationModifier + noise, to: -1...1)
    }

    /// The rating term alone, without noise. Exposed because it is the part with a stated shape,
    /// and a test that had to average out the noise to see the shape would be a worse test.
    ///
    /// Maps a rating difference to (-1, 1) through a logistic centred on zero. At a difference of
    /// zero it returns exactly zero, so an even matchup is even.
    public static func logistic(_ ratingDifference: Double) -> Double {
        2 / (1 + Foundation.exp(-ratingDifference / MatchupRules.leverageScale)) - 1
    }

    /// The steepest slope of `logistic`, at a difference of zero. `1 / (2 * scale)`.
    ///
    /// Named rather than recomputed at call sites, because it is what "a 10-point gap matters more
    /// in the middle" means quantitatively.
    public static var peakSlope: Double { 1 / (2 * MatchupRules.leverageScale) }

    private static func clampUnit(_ value: Double) -> Double { clamp(value, to: -1...1) }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(value, range.lowerBound), range.upperBound)
    }
}
