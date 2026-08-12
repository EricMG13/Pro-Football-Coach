import SwiftUI

/// Resolves a generated team's colour pair into the surfaces the management frame may paint.
///
/// `04` section 5 lets programme colour own the world-strip field, the uniform mark and selection
/// state; it forbids a decorative team-colour wash on management panels. This type is the only
/// place that decision is made, so a view cannot quietly widen it.
///
/// Two contrast rules from `04` section 6.1 are mandatory here rather than stylistic, because
/// generated colour cannot be assumed to clear any floor:
///
/// 1. The ink on a team field is chosen by measurement, not by taste, and must reach 4.5:1. A pair
///    that cannot be read at all resolves to `nil` and the caller keeps its neutral furniture —
///    an honest fallback beats an illegible identity.
/// 2. A team surface below 3:1 against the surface behind it carries a hairline boundary. The
///    low-chroma reference primary measures 2.67 on dark `work`, so this case is real, not
///    theoretical.
public struct CoachWorldTeamIdentity: Sendable, Equatable {
    /// The team's primary, used as a field behind world context.
    public let field: CoachWorldTokens.ColorValue
    /// The team's secondary, used for the uniform mark and selection rule.
    public let accent: CoachWorldTokens.ColorValue
    /// Measured-legible ink for text sitting on `field`.
    public let onField: CoachWorldTokens.ColorValue
    /// True when `field` sits below the 3:1 non-text floor against the surface behind it.
    public let needsBoundary: Bool

    /// Nil when the team carries no colour pair, or when no candidate ink reaches the 4.5:1 body
    /// floor on it. `inks` is an unordered candidate set — the winner is measured, not preferred,
    /// because which of the palette's inks reads on a generated colour flips with appearance.
    public init?(
        team: CoachWorldTeamReference,
        behind surface: CoachWorldTokens.ColorValue,
        inks: [CoachWorldTokens.ColorValue]
    ) {
        guard let primary = CoachWorldTokens.ColorValue(hexString: team.primaryColorHex),
              let secondary = CoachWorldTokens.ColorValue(hexString: team.secondaryColorHex),
              let best = primary.mostLegibleInk(from: inks),
              primary.contrast(against: best) >= CoachWorldTeamIdentity.bodyTextFloor
        else { return nil }

        field = primary
        accent = secondary
        onField = best
        needsBoundary = primary.contrast(against: surface) < CoachWorldTeamIdentity.nonTextFloor
    }

    /// The rule colour for a selected row: whichever of the pair a reader can actually see against
    /// the working surface, and nothing when neither clears the non-text floor.
    public func selectionRule(on surface: CoachWorldTokens.ColorValue)
        -> CoachWorldTokens.ColorValue? {
        let candidates = [accent, field]
            .filter { $0.contrast(against: surface) >= CoachWorldTeamIdentity.nonTextFloor }
        return candidates.max { $0.contrast(against: surface) < $1.contrast(against: surface) }
    }

    public static let bodyTextFloor = 4.5
    public static let nonTextFloor = 3.0
}

public extension CoachWorldTokens.ColorValue {
    /// Parses `#RRGGBB` or `RRGGBB`. Anything else is not a colour and returns nil rather than
    /// guessing — a malformed identity must fall back to neutral furniture, not to black.
    init?(hexString: String?) {
        guard let hexString else { return nil }
        let digits = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(hex: value)
    }

    /// WCAG 2.2 relative luminance.
    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// The candidate that reads best on this colour, by measurement rather than by appearance.
    func mostLegibleInk(from candidates: [CoachWorldTokens.ColorValue])
        -> CoachWorldTokens.ColorValue? {
        candidates.max { contrast(against: $0) < contrast(against: $1) }
    }

    /// WCAG 2.2 contrast ratio, order-independent.
    func contrast(against other: CoachWorldTokens.ColorValue) -> Double {
        let first = relativeLuminance
        let second = other.relativeLuminance
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }
}
