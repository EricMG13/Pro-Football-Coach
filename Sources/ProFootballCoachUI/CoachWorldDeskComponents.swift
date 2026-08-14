import SwiftUI

/// The role an action plays — `04` §3's Decide / Inspect / Delegate stay distinct.
public enum CoachWorldActionRole {
    case primary
    case secondary
    case live
}

/// Registry 2's styling form, for call sites that style a `Button` rather than build a `GoButton`.
///
/// `GoButton` is the composed control and the one to reach for. This style remains for buttons that
/// already exist inside a screen's own composition, and it inks a filled control with the ground
/// rather than with `content.primary`, which measures 1.51 on the gold fill (`04` §6.1).
public struct CoachWorldActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public let role: CoachWorldActionRole
    public let palette: CoachWorldTokens.Palette

    public init(role: CoachWorldActionRole, palette: CoachWorldTokens.Palette) {
        self.role = role
        self.palette = palette
    }

    public func makeBody(configuration: Configuration) -> some View {
        let appearance = self.appearance
        let controlShape = CutCorner.action

        return configuration.label
            .font(CoachWorldTokens.TypeRole.body.weight(.bold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(
                minWidth: CoachWorldTokens.Shape.minimumTarget,
                minHeight: CoachWorldTokens.Shape.minimumTarget
            )
            .foregroundStyle(appearance.foreground)
            .background(
                configuration.isPressed
                    ? appearance.fill.opacity(0.76)
                    : appearance.fill
            )
            .overlay {
                controlShape.strokeBorder(
                    appearance.border,
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .clipShape(controlShape)
            .opacity(isEnabled ? 1 : 0.45)
    }

    private var appearance: (fill: Color, foreground: Color, border: Color) {
        switch role {
        case .primary:
            let accent = palette.actionPrimary.color
            return (accent, palette.page.color, accent)
        case .secondary:
            return (
                palette.raised.color,
                palette.contentPrimary.color,
                palette.contentQuiet.color
            )
        case .live:
            let accent = palette.stateLive.color
            return (accent, palette.page.color, accent)
        }
    }
}

/// Registry 1 — the local-route navigation control.
///
/// **Now Floodlit's pill geometry**, carried on the registry name rather than beside it: `04` §6.5
/// binds each registry entry to exactly one Swift type, so a second route control under a second
/// name would break the rule the registry exists to state, however good the geometry.
///
/// The drawn height is the pill's; the hit target is the 44 pt floor `04` §6.3 requires, which is
/// why the two frames differ.
public struct CoachWorldRouteButton: View {
    @Environment(\.coachWorldPalette) private var environmentPalette
    @Environment(\.coachWorldFills) private var fills

    private let title: String
    private let isCurrent: Bool
    private let explicitPalette: CoachWorldTokens.Palette?
    /// Selection furniture speaks in the programme's colour where it is legible. Defaulting to the
    /// tier token keeps a screen that has not been given an identity unchanged.
    private let selection: CoachWorldTokens.ColorValue?
    private let action: () -> Void

    public init(
        title: String,
        isCurrent: Bool,
        palette: CoachWorldTokens.Palette? = nil,
        selection: CoachWorldTokens.ColorValue? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isCurrent = isCurrent
        explicitPalette = palette
        self.selection = selection
        self.action = action
    }

    private var palette: CoachWorldTokens.Palette { explicitPalette ?? environmentPalette }
    private var selectionColour: CoachWorldTokens.ColorValue { selection ?? palette.actionPrimary }

    public var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(CoachWorldTokens.TypeRole.display(CoachWorldTokens.Control.pillTextSize))
                .tracking(CoachWorldTokens.Control.pillTracking)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .foregroundStyle(ink)
                .padding(.horizontal, CoachWorldTokens.Control.pillInset)
                .frame(minHeight: CoachWorldTokens.Control.pillHeight)
                .background { field }
                .contentShape(Rectangle())
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var ink: Color {
        isCurrent ? fills.onFill.color : palette.contentSecondary.color
    }

    @ViewBuilder private var field: some View {
        let shape = CutCorner.row
        if isCurrent {
            shape.fill(LinearGradient(
                colors: [CoachWorldTokens.Gauge.arcLight.color, selectionColour.color],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        } else {
            shape.fill(CoachWorldTokens.Control.pillGhostFill.color)
                .overlay(shape.strokeBorder(
                    CoachWorldTokens.Glass.edge.color,
                    lineWidth: CoachWorldTokens.Shape.hairline
                ))
        }
    }
}

private struct CoachWorldDeskSurfaceModifier: ViewModifier {
    let fill: Color
    let border: Color

    func body(content: Content) -> some View {
        content
            .background { CutCorner.panel.fill(fill) }
            .overlay {
                CutCorner.panel.strokeBorder(border, lineWidth: CoachWorldTokens.Shape.hairline)
            }
            .clipShape(CutCorner.panel)
    }
}

public extension View {
    /// Registry 3 — the matte opaque panel treatment.
    ///
    /// **This is `GlassPanel`'s opaque counterpart, not its rival.** `04` §6.1 budgets at most two
    /// material panels per screen; every other surface takes this. It is also what a glass panel
    /// becomes when the blur budget is spent — the same fill `GlassPanel` falls back to under
    /// Reduce Transparency.
    func coachWorldDeskSurface(fill: Color, border: Color) -> some View {
        modifier(CoachWorldDeskSurfaceModifier(fill: fill, border: border))
    }
}
