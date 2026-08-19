import SwiftUI

/// The one place a custom-sized font may be constructed in `ProFootballCoachUI`.
///
/// S-0, 2026-08-19 adversarial review: `CoachWorldTokens.display(_:weight:)` and
/// `figure(_:weight:)` returned `.system(size:weight:)` with no `relativeTo:`, so no custom-sized
/// text in the app grows under Dynamic Type — every `isAccessibilitySize` branch elsewhere in the
/// codebase reflows *layout* around type that never changes size. `04` section 6.2 states the rule
/// this file exists to satisfy: *"Custom sizes are wrapped in `@ScaledMetric` so the default
/// composition remains dense while accessibility categories can expand and reflow it."*
///
/// `@ScaledMetric` can only live on a stored property that SwiftUI re-evaluates against the current
/// environment, which a static function returning a bare `Font` cannot provide. This file is that
/// property's one home: a `ViewModifier` whose `@ScaledMetric` is seeded from a caller-supplied base
/// size via the underscored-backing-storage initialiser SwiftUI provides for exactly this case, and
/// two `View` extension methods — `coachWorldDisplay`/`coachWorldFigure` — that are the scaling
/// replacements for `CoachWorldTokens.display`/`figure`. A source scan should eventually assert that
/// `.system(size:` and `CoachWorldTokens.display(`/`figure(` no longer appear as a `.font(...)`
/// argument outside this file and `DesignTokens.swift` itself, the same shape
/// `MotionContractTests.swift` already uses for `CoachWorldMotion.swift`.
///
/// `relativeTo:` defaults to `.body` for every caller that does not name one. Canon gives an exact
/// text-style mapping for the six semantic roles (`TypeRole.display/.title/.headline/.body/
/// .callout/.caption`, `04` section 6.2 lines 626-632) — already implemented and already scaling —
/// but gives no equivalent mapping for `DisplaySize`'s granular numeric scale (66 down to 9). `.body`
/// is SwiftUI's own default for an unspecified `@ScaledMetric` and produces a single, uniform,
/// predictable growth rate; picking a materially different rate per size is a design judgement this
/// file does not make unilaterally. A call site that has a real reason to grow faster or slower may
/// pass a specific `textStyle`.
private struct CoachWorldScaledFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let condensed: Bool
    let monospacedDigit: Bool

    init(
        size: CGFloat, relativeTo textStyle: Font.TextStyle, weight: Font.Weight,
        condensed: Bool, monospacedDigit: Bool
    ) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.condensed = condensed
        self.monospacedDigit = monospacedDigit
    }

    func body(content: Content) -> some View {
        var font = Font.system(size: size, weight: weight)
        if condensed { font = font.width(.condensed) }
        if monospacedDigit { font = font.monospacedDigit() }
        return content.font(font)
    }
}

extension View {
    /// Display type: SF Pro Condensed, uppercase by convention at the call site. The scaling
    /// replacement for `.font(CoachWorldTokens.display(size, weight: weight))`.
    func coachWorldDisplay(
        _ size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body,
        weight: Font.Weight = .bold
    ) -> some View {
        modifier(CoachWorldScaledFontModifier(
            size: size, relativeTo: textStyle, weight: weight,
            condensed: true, monospacedDigit: false
        ))
    }

    /// Figures: the system face with tabular digits, so a score or a clock does not reflow as it
    /// counts. The scaling replacement for `.font(CoachWorldTokens.figure(size, weight: weight))`.
    func coachWorldFigure(
        _ size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body,
        weight: Font.Weight = .bold
    ) -> some View {
        modifier(CoachWorldScaledFontModifier(
            size: size, relativeTo: textStyle, weight: weight,
            condensed: false, monospacedDigit: true
        ))
    }
}
