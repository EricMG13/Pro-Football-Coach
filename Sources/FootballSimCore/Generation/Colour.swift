import Foundation

/// An sRGB colour, 8 bits per channel.
///
/// The engine owns colour because `04-UX-AND-DESIGN-SYSTEM.md` §2.1 requires a generated team pair
/// to pass the trade-dress and contrast tests **at generation time** — a pair that cannot carry
/// legible text is rejected and regenerated, rather than failing at the call site the way the prior
/// build's "white on the team gradient" class of defects did. That means the maths lives here, in a
/// module with zero UI imports, not in the design system.
public struct Colour: Codable, Sendable, Equatable, Hashable {
    public let red: Int
    public let green: Int
    public let blue: Int

    public init(red: Int, green: Int, blue: Int) {
        self.red = Colour.channel(red)
        self.green = Colour.channel(green)
        self.blue = Colour.channel(blue)
    }

    /// From `RRGGBB`, with or without a leading `#`. Anything unparseable is black rather than a
    /// trap: this reads a blocklist that is edited by hand.
    public init(hex: String) {
        var digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if digits.count != 6 { digits = "000000" }
        let value = UInt32(digits, radix: 16) ?? 0
        self.init(red: Int((value >> 16) & 0xFF),
                  green: Int((value >> 8) & 0xFF),
                  blue: Int(value & 0xFF))
    }

    public var hex: String {
        String(format: "%02X%02X%02X", red, green, blue)
    }

    private static func channel(_ value: Int) -> Int {
        Swift.min(Swift.max(value, 0), 255)
    }

    // MARK: - Perceptual distance

    /// CIE76 ΔE between two colours in L\*a\*b\*.
    ///
    /// `02` §11.3.5 fixes the space and the formula. CIE76 is the cheapest perceptual distance that
    /// is not RGB, needs no dependency, and — importantly for a legal gate — is simple enough that
    /// the threshold can be argued about rather than taken on trust.
    public func deltaE(to other: Colour) -> Double {
        let (l1, a1, b1) = lab
        let (l2, a2, b2) = other.lab
        let dl = l1 - l2, da = a1 - a2, db = b1 - b2
        return (dl * dl + da * da + db * db).squareRoot()
    }

    /// L\*a\*b\* under a D65 white point.
    public var lab: (l: Double, a: Double, b: Double) {
        let (x, y, z) = xyz
        // D65 reference white, scaled to the same 0...1 range as `xyz`.
        let fx = Colour.labCurve(x / 0.950_489)
        let fy = Colour.labCurve(y / 1.0)
        let fz = Colour.labCurve(z / 1.088_840)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }

    private var xyz: (x: Double, y: Double, z: Double) {
        let r = Colour.linearise(Double(red) / 255)
        let g = Colour.linearise(Double(green) / 255)
        let b = Colour.linearise(Double(blue) / 255)
        return (
            0.412_456_4 * r + 0.357_576_1 * g + 0.180_437_5 * b,
            0.212_672_9 * r + 0.715_152_2 * g + 0.072_175_0 * b,
            0.019_333_9 * r + 0.119_192_0 * g + 0.950_304_1 * b
        )
    }

    private static func labCurve(_ t: Double) -> Double {
        t > 0.008_856_45 ? Foundation.pow(t, 1.0 / 3.0) : (t * 903.296_3 + 16) / 116
    }

    // MARK: - Contrast

    /// WCAG relative luminance.
    public var relativeLuminance: Double {
        0.2126 * Colour.linearise(Double(red) / 255)
            + 0.7152 * Colour.linearise(Double(green) / 255)
            + 0.0722 * Colour.linearise(Double(blue) / 255)
    }

    /// WCAG contrast ratio, 1.0 to 21.0. Order-independent.
    public func contrastRatio(against other: Colour) -> Double {
        let a = relativeLuminance, b = other.relativeLuminance
        let lighter = Swift.max(a, b), darker = Swift.min(a, b)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func linearise(_ channel: Double) -> Double {
        channel <= 0.040_45 ? channel / 12.92 : Foundation.pow((channel + 0.055) / 1.055, 2.4)
    }

    public static let white = Colour(red: 255, green: 255, blue: 255)
    public static let black = Colour(red: 0, green: 0, blue: 0)
}

/// A team's generated identity colours.
public struct ColourPair: Codable, Sendable, Equatable, Hashable {
    public let primary: Colour
    public let secondary: Colour

    /// Whichever of white or black carries legible text on `primary`. `04` §2.1's `team.onTeam`.
    public let onTeam: Colour

    public init(primary: Colour, secondary: Colour, onTeam: Colour) {
        self.primary = primary
        self.secondary = secondary
        self.onTeam = onTeam
    }

    /// How legible text on the primary is. `04` §2.1 floors this at 4.5:1.
    public var textContrast: Double { onTeam.contrastRatio(against: primary) }

    /// How distinguishable the secondary is on the primary. `04` §2.1 floors this at 3:1.
    ///
    /// A separate number from `textContrast` because they are separate obligations. The first
    /// version of this type had one `worstContrast` over both members, which requires a single
    /// foreground to work on a dark colour *and* a light one — unsatisfiable for most real
    /// identities, and the fallback pairs failed it four ways.
    public var secondaryContrast: Double { secondary.contrastRatio(against: primary) }
}
