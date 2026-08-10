import Foundation

/// Generates team colour pairs that pass both legal and accessibility constraints **before** they
/// exist, per `04-UX-AND-DESIGN-SYSTEM.md` §2.1.
///
/// This is the structural answer to the prior build's "white on the team gradient" class of
/// defects: they were call-site failures because the colours were unconstrained at the source. A
/// pair that cannot carry legible text is never constructed here, so no surface downstream has to
/// remember to check.
public enum ColourGenerator {
    /// `02` §11.3.5 and `04` §2.1.
    public static let tradeDressThreshold = 25.0
    /// `team.onTeam` on `team.primary`. WCAG AA for body text.
    ///
    /// **This floor cannot currently reject anything, and that is a fact worth stating rather than
    /// hiding.** `legibleForeground` picks the better of white and black, which gives
    /// `max(1.05 / (L + 0.05), (L + 0.05) / 0.05)`; the two branches cross at L = 0.1791 where both
    /// equal the square root of 21, about 4.583. So the worst case over the entire sRGB gamut is
    /// already above 4.5 and the guard is satisfied by construction.
    ///
    /// It stays because it is the *contract* `04` §2.1 states, and the moment `onTeam` becomes
    /// anything other than a white-or-black choice — a tinted foreground, a third generated colour —
    /// the guard starts binding. The floor that actually filters pairs today is
    /// `secondaryContrastFloor`.
    public static let textContrastFloor = 4.5
    /// `team.secondary` on `team.primary`. WCAG AA for non-text elements.
    public static let secondaryContrastFloor = 3.0
    public static let retryBudget = 64

    /// True if `pair` sits within ΔE of a real programme's pair, in either orientation.
    ///
    /// **Both** members must be close. One shared colour is not trade dress; half the sport wears
    /// navy, and a threshold that rejected navy would leave the generator nothing to work with.
    public static func collidesWithTradeDress(_ primary: Colour, _ secondary: Colour) -> Bool {
        Blocklist.tradeDress.contains { real in
            let straight = primary.deltaE(to: real.primary) < tradeDressThreshold
                && secondary.deltaE(to: real.secondary) < tradeDressThreshold
            let swapped = primary.deltaE(to: real.secondary) < tradeDressThreshold
                && secondary.deltaE(to: real.primary) < tradeDressThreshold
            return straight || swapped
        }
    }

    /// The better of white and black on `primary`, and the contrast it achieves.
    public static func legibleForeground(on primary: Colour) -> (colour: Colour, contrast: Double) {
        let onWhite = Colour.white.contrastRatio(against: primary)
        let onBlack = Colour.black.contrastRatio(against: primary)
        // Deterministic tie-break: white wins an exact tie, so the same primary always resolves the
        // same way whatever order the comparison runs in.
        return onWhite >= onBlack ? (Colour.white, onWhite) : (Colour.black, onBlack)
    }

    /// Both floors from `04` §2.1, in one place so generation and the legal sweep cannot diverge.
    public static func satisfiesContrastContract(_ pair: ColourPair) -> Bool {
        pair.textContrast >= textContrastFloor && pair.secondaryContrast >= secondaryContrastFloor
    }

    /// A pair drawn from `rng` that passes both constraints.
    ///
    /// Bounded, because a generator that can loop forever is a hang rather than a bug. After
    /// `retryBudget` attempts it returns a deterministic fallback drawn from a pre-verified set —
    /// and the fallbacks are themselves swept by both legal tests, so the escape hatch cannot be
    /// the hole. `GenerationTests` asserts the budget is never exhausted at ordinary seeds, so a
    /// silent slide onto the fallback shows up as a failure rather than as duplicate colours.
    public static func pair(using rng: inout SeededRandom, fallbackIndex: Int) -> ColourPair {
        for _ in 0..<retryBudget {
            let primary = saturatedColour(using: &rng)
            let secondary = saturatedColour(using: &rng)
            guard !collidesWithTradeDress(primary, secondary) else { continue }
            // A pair whose two colours are perceptually the same is not a pair.
            guard primary.deltaE(to: secondary) >= tradeDressThreshold else { continue }
            let candidate = ColourPair(primary: primary, secondary: secondary,
                                       onTeam: legibleForeground(on: primary).colour)
            guard satisfiesContrastContract(candidate) else { continue }
            return candidate
        }
        return fallback(fallbackIndex)
    }

    /// A pre-verified pair, chosen by index. Covered by both legal tests like any other.
    public static func fallback(_ index: Int) -> ColourPair {
        let pair = fallbackPairs[((index % fallbackPairs.count) + fallbackPairs.count)
            % fallbackPairs.count]
        return ColourPair(primary: pair.0, secondary: pair.1,
                          onTeam: legibleForeground(on: pair.0).colour)
    }

    public static var fallbackCount: Int { fallbackPairs.count }

    /// Colours with enough saturation to read as an identity rather than as a grey, and enough
    /// range in lightness that a pair can find a legible foreground.
    private static func saturatedColour(using rng: inout SeededRandom) -> Colour {
        let hue = Double(rng.int(in: 0...359))
        let saturation = Double(rng.int(in: 45...95)) / 100
        let lightness = Double(rng.int(in: 12...78)) / 100
        return Colour(hue: hue, saturation: saturation, lightness: lightness)
    }

    /// Deep, high-contrast pairs, each checked against the trade-dress list and both contrast
    /// floors by `LegalTests` rather than by having been eyeballed.
    ///
    /// Found by search rather than by taste: the first, hand-picked set failed the fallback test
    /// four different ways, which is exactly what that test exists to say.
    private static let fallbackPairs: [(Colour, Colour)] = [
        (Colour(hex: "463F10"), Colour(hex: "F4C03E")),
        (Colour(hex: "1B1958"), Colour(hex: "51B870")),
        (Colour(hex: "0A3921"), Colour(hex: "18EC18")),
        (Colour(hex: "0E2E05"), Colour(hex: "2CB927")),
        (Colour(hex: "211033"), Colour(hex: "D67DD9")),
        (Colour(hex: "081077"), Colour(hex: "B23BBA")),
        (Colour(hex: "521419"), Colour(hex: "74E2BF")),
        (Colour(hex: "66490B"), Colour(hex: "C8A179")),
    ]
}

public extension Colour {
    /// From HSL, which is the space a generator wants: hue picks an identity, saturation keeps it
    /// from being grey, and lightness is the dial that decides whether text can sit on it.
    init(hue: Double, saturation: Double, lightness: Double) {
        // Normalised into [0, 360) before the sector maths, not merely wrapped. `truncatingRemainder`
        // keeps the sign, so a negative hue landed in a negative sector and `Int(h)` truncated
        // toward zero: 359 of 360 negative hues returned a different colour from their positive
        // equivalent. Nothing in the generator passes a negative hue today, which is why no test
        // saw it, and a public initialiser that is wrong for half its domain is a trap for whoever
        // does.
        let wrapped = hue.truncatingRemainder(dividingBy: 360)
        let h = (wrapped < 0 ? wrapped + 360 : wrapped) / 60
        let c = (1 - Swift.abs(2 * lightness - 1)) * saturation
        let x = c * (1 - Swift.abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2
        let (r, g, b): (Double, Double, Double)
        switch Int(h) {
        case 0: (r, g, b) = (c, x, 0)
        case 1: (r, g, b) = (x, c, 0)
        case 2: (r, g, b) = (0, c, x)
        case 3: (r, g, b) = (0, x, c)
        case 4: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        self.init(red: Int(((r + m) * 255).rounded()),
                  green: Int(((g + m) * 255).rounded()),
                  blue: Int(((b + m) * 255).rounded()))
    }
}
