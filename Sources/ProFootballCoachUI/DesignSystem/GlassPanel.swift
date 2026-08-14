import SwiftUI

/// Registry 25 — a pane of glass held above the world.
///
/// Three things make it read as glass rather than a grey card: the material blurs what is behind
/// it, a hairline traces the cut edge, and a sheen falls from the upper leading corner — the same
/// direction as the light in every world.
///
/// **Depth is a contrast decision before it is a visual one.** `04` §6.1: a standard panel cannot
/// carry body text over a lit world, because the standard fill composited over the brightest turf
/// resolves to `#42AD70`, on which `content.primary` measures 2.69. Prose needs `.deep`. Labels and
/// figures may sit on `.standard`.
///
/// **Reduce Transparency flattens it**, per `04` §7: the material and sheen are dropped and the
/// panel takes the opaque equivalent named in §6.1. Depth order survives the flattening — standard
/// becomes `world.work`, which §6.1 defines as the standard glass composited over `world.page`, and
/// deep becomes `world.raised`, the next elevation up. Every measured ratio survives with it,
/// which is why §6.1 measures against the opaque equivalents rather than the composited glass.
public struct GlassPanel<Content: View>: View {
    public enum Depth {
        /// Sits close to the world; the world reads through it. Labels and figures only.
        case standard
        /// Pushed forward for text that has to be read. Required for prose over a lit world.
        case deep
    }

    @Environment(\.coachWorldPalette) private var palette
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let shape: CutCorner
    private let depth: Depth
    private let content: Content

    public init(
        shape: CutCorner = .panel,
        depth: Depth = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.shape = shape
        self.depth = depth
        self.content = content()
    }

    public var body: some View {
        content
            .background { background }
            .overlay(shape.strokeBorder(edgeColor, lineWidth: CoachWorldTokens.Shape.hairline))
            .shadow(
                color: .black.opacity(CoachWorldTokens.Elevation.panelShadowOpacity),
                radius: CoachWorldTokens.Elevation.panelShadowRadius,
                x: .zero,
                y: CoachWorldTokens.Elevation.panelShadowOffsetY
            )
    }

    @ViewBuilder
    private var background: some View {
        if reduceTransparency {
            shape.fill(opaqueEquivalent.color)
        } else {
            shape.fill(.ultraThinMaterial)
                .overlay(shape.fill(fill.color))
                .overlay(shape.fill(sheen))
        }
    }

    /// `04` §6.1's opaque equivalents, which is what the flattened form takes.
    private var opaqueEquivalent: CoachWorldTokens.ColorValue {
        switch depth {
        case .standard: palette.work
        case .deep: palette.raised
        }
    }

    private var fill: CoachWorldTokens.AtmosphereStop {
        switch depth {
        case .standard: CoachWorldTokens.Glass.standardFill
        case .deep: CoachWorldTokens.Glass.deepFill
        }
    }

    /// The glass edge is a **structural** rule under `04` §6.1's two-hairline test: it carries no
    /// meaning and never substitutes for the legible seam.
    private var edgeColor: Color {
        reduceTransparency
            ? palette.contentQuiet.color.opacity(CoachWorldTokens.Glass.structuralRule.alpha)
            : CoachWorldTokens.Glass.edge.color
    }

    private var sheen: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: CoachWorldTokens.Glass.sheen.color, location: 0),
                .init(color: .clear, location: 0.42)
            ],
            startPoint: UnitPoint(x: 0.1, y: 0),
            endPoint: UnitPoint(x: 0.75, y: 0.9)
        )
    }
}
