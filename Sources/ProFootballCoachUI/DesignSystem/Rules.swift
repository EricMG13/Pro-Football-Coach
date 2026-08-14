import SwiftUI

/// The two hairline jobs of `04` §6.1, which are different work and take different values.
///
/// This existed as nine hand-copied `seam` and `verticalSeam` properties across five screens, at
/// two different opacities, and **one of the nine omitted `.accessibilityHidden(true)`** — so
/// `CoachingHQView`'s rules were announced to VoiceOver as elements. That is the cost of copying a
/// one-line view: the copies drift, and the drift is invisible until someone reads all nine.
public enum CoachWorldRule {
    /// **Structural rule** — separating continuous regions of one surface.
    ///
    /// Deliberately near-invisible (`world.raised` over `work`, 1.16 dark / 1.25 light): it groups,
    /// it does not signal, and a rule the eye stops on is a container pretending to be a rule.
    case structural
    /// **Legible seam** — where a divider must actually be seen, on a `raised` surface or against
    /// generated colour. Draws in `content.quiet`: 4.97 on dark `raised`, 4.78 on light.
    case legible
}

private struct CoachWorldSeam: View {
    @Environment(\.coachWorldPalette) private var palette

    let rule: CoachWorldRule
    let axis: Axis

    var body: some View {
        Rectangle()
            .fill(tint)
            .frame(
                width: axis == .vertical ? CoachWorldTokens.Shape.hairline : nil,
                height: axis == .horizontal ? CoachWorldTokens.Shape.hairline : nil
            )
            // Never an element. A rule carries no meaning alone (`04` §6.1), so announcing it
            // gives a screen reader a stop with nothing to say.
            .accessibilityHidden(true)
    }

    private var tint: Color {
        switch rule {
        case .structural: palette.raised.color
        case .legible: palette.contentQuiet.color
        }
    }
}

public extension View {
    /// A horizontal rule beneath this view.
    func coachWorldSeam(
        _ rule: CoachWorldRule = .legible,
        alignment: Alignment = .bottom
    ) -> some View {
        overlay(alignment: alignment) { CoachWorldSeam(rule: rule, axis: .horizontal) }
    }

    /// A vertical rule at the trailing edge of this view.
    func coachWorldVerticalSeam(
        _ rule: CoachWorldRule = .legible,
        alignment: Alignment = .trailing
    ) -> some View {
        overlay(alignment: alignment) { CoachWorldSeam(rule: rule, axis: .vertical) }
    }
}

/// The heat bands of `04` §6.4: a rating's colour is a third reading beside its figure and its
/// ring, never the only one.
///
/// Defined once. It was two byte-identical copies in `RosterView` and `PlayerProfileView`, and
/// nothing else in the target used the thresholds — so Recruiting Board's ratings were unbanded
/// simply because nobody copied the function a third time.
public enum CoachWorldHeat: Sendable {
    case strong, middling, weak

    /// `04` §6.4 fixes the bands at 85 and 70 on the 40–99 rating scale.
    public static func band(_ rating: Int) -> CoachWorldHeat {
        if rating >= 85 { return .strong }
        if rating >= 70 { return .middling }
        return .weak
    }

    public func ink(_ palette: CoachWorldTokens.Palette) -> Color {
        switch self {
        case .strong: palette.statePositive.color
        case .middling: palette.stateWarning.color
        case .weak: palette.stateNegative.color
        }
    }

    /// The spoken band, so a screen reader hears the judgement the colour carries. `04` §6.1:
    /// state is never colour alone.
    public var spoken: String {
        switch self {
        case .strong: "elite"
        case .middling: "solid"
        case .weak: "weak"
        }
    }
}
