import SwiftUI

/// A tracked, uppercase micro-label — used wherever a field needs naming without competing with its
/// value.
///
/// **Ships at 10 pt, not Floodlit's 9.** `04` §6.2 settles this: 9 pt is below the Caption floor and
/// below `04b` §8's authored-type check, which machine-checks that no authored type falls under
/// 12 pt with the micro-label class floored at 10. The tracking is kept — this is the one place
/// tracking above −0.2 pt is correct, because an uppercase micro-label is read as a shape.
///
/// Scaled against `.caption`, so the dense default composition survives while accessibility
/// categories expand it.
public struct CoachWorldFieldLabel: View {
    @Environment(\.coachWorldPalette) private var palette
    @ScaledMetric(relativeTo: .caption) private var size = CoachWorldTokens.TypeRole.microLabel

    private let text: String
    private let tint: CoachWorldTokens.ColorValue?

    public init(_ text: String, tint: CoachWorldTokens.ColorValue? = nil) {
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        Text(text.uppercased())
            .font(CoachWorldTokens.TypeRole.display(size, .bold))
            .tracking(size * CoachWorldTokens.TypeRole.microLabelTracking)
            .foregroundStyle((tint ?? palette.contentQuiet).color)
    }
}

public extension Text {
    /// The display gradient: white falling to a cool grey, so a headline reads as lit from above.
    ///
    /// `04` §6.2 measures a gradient type fill **at its worst stop**, which is the foot of the
    /// glyph rather than its top: `#93A8C0` measures 8.12 / 7.14 / 6.16 on page / work / raised and
    /// 5.85 over the worst lamp-lit ground, so it clears the body floor everywhere. Any future
    /// gradient fill is measured the same way.
    func coachWorldLitFill() -> some View {
        foregroundStyle(
            LinearGradient(
                colors: [.white, CoachWorldTokens.Atmosphere.displayGradientFoot.color],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

public extension View {
    /// Line spacing for wrapping prose, as a fraction of the type size.
    func coachWorldProse(_ size: CGFloat, ratio: CGFloat = 0.45) -> some View {
        lineSpacing(size * ratio)
    }
}
