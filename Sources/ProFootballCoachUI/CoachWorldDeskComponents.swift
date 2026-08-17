import SwiftUI

/// The asymmetric four-corner shape `04` section 6.1a names: independent radii per corner, so a
/// panel reads as a deliberate cut shape rather than a default rounded card. `RoundedRectangle`
/// cannot express this — each corner needs its own radius, drawn by hand.
struct CoachWorldCutCorner: Shape {
    var topLeading: CGFloat
    var topTrailing: CGFloat
    var bottomTrailing: CGFloat
    var bottomLeading: CGFloat

    init(
        topLeading: CGFloat = 4,
        topTrailing: CGFloat = 22,
        bottomTrailing: CGFloat = 4,
        bottomLeading: CGFloat = 22
    ) {
        self.topLeading = topLeading
        self.topTrailing = topTrailing
        self.bottomTrailing = bottomTrailing
        self.bottomLeading = bottomLeading
    }

    /// The house panel shape — glass panels, cards.
    static let panel = CoachWorldCutCorner()
    /// Rows and chips — a tighter variant of `.panel`.
    static let row = CoachWorldCutCorner(
        topLeading: 3, topTrailing: 14, bottomTrailing: 3, bottomLeading: 14
    )
    /// Committing controls: soft on three corners, cut on the last.
    static let action = CoachWorldCutCorner(
        topLeading: 22, topTrailing: 22, bottomTrailing: 22, bottomLeading: 5
    )

    func path(in rect: CGRect) -> Path {
        let maxRadius = min(rect.width, rect.height) / 2
        let tl = min(topLeading, maxRadius)
        let tr = min(topTrailing, maxRadius)
        let br = min(bottomTrailing, maxRadius)
        let bl = min(bottomLeading, maxRadius)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr,
            startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(
            center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br,
            startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl,
            startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(
            center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl,
            startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

/// DESK gets the full committed backdrop (gradient, glow, grain). BROADCAST is flat `page.color`
/// only — the render-recorded-match contract forbids desk chrome, gradients, and glow on a live
/// match surface, so Match Day and Aftermath opt out rather than inheriting it.
enum CoachWorldRegister {
    case desk
    case broadcast
}

enum CoachWorldFloodlitPanelDepth {
    case glass
    case deep

    var opacity: Double {
        switch self {
        case .glass: CoachWorldTokens.Depth.glassPanelOpacity
        case .deep: CoachWorldTokens.Depth.deepPanelOpacity
        }
    }
}

struct CoachWorldFloodlitStage<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let palette: CoachWorldTokens.Palette
    let register: CoachWorldRegister
    @ViewBuilder let content: () -> Content

    init(
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        register: CoachWorldRegister = .desk,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.register = register
        self.content = content
    }

    var body: some View {
        ZStack {
            palette.page.color
            if register == .desk {
                CoachWorldFloodlitBackdrop(palette: palette)
            }
            content()
            if register == .desk, !reduceTransparency {
                CoachWorldGrainOverlay()
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("floodlit-stage")
    }
}

private struct CoachWorldFloodlitBackdrop: View {
    let palette: CoachWorldTokens.Palette

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [palette.page.color, palette.work.color, palette.page.color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color(red: 1, green: 0.95, blue: 0.78).opacity(0.22), .clear],
                    center: UnitPoint(x: 0.78, y: 0.02),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.52
                )

                Canvas { context, size in
                    var pitch = Path()
                    pitch.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.42))
                    pitch.addLine(to: CGPoint(x: size.width * 0.86, y: size.height * 0.42))
                    pitch.addLine(to: CGPoint(x: size.width * 1.08, y: size.height * 1.02))
                    pitch.addLine(to: CGPoint(x: size.width * -0.08, y: size.height * 1.02))
                    pitch.closeSubpath()
                    context.fill(
                        pitch,
                        with: .linearGradient(
                            Gradient(colors: [
                                palette.fieldTurf.color.opacity(0.12),
                                palette.fieldTurf.color.opacity(0.34),
                            ]),
                            startPoint: CGPoint(x: size.width / 2, y: size.height * 0.42),
                            endPoint: CGPoint(x: size.width / 2, y: size.height)
                        )
                    )

                    for index in 0..<7 {
                        let progress = CGFloat(index) / 6
                        let y = size.height * (0.47 + progress * 0.48)
                        let inset = size.width * (0.16 - progress * 0.19)
                        var line = Path()
                        line.move(to: CGPoint(x: inset, y: y))
                        line.addLine(to: CGPoint(x: size.width - inset, y: y))
                        context.stroke(
                            line,
                            with: .color(palette.fieldLine.color.opacity(0.07)),
                            lineWidth: CoachWorldTokens.Shape.hairline
                        )
                    }
                }
            }
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

private struct CoachWorldGrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<140 {
                let x = CGFloat((index * 73) % 997) / 997 * size.width
                let y = CGFloat((index * 151) % 991) / 991 * size.height
                let alpha = index.isMultiple(of: 3) ? 0.035 : 0.018
                context.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum CoachWorldActionRole {
    case primary
    case secondary
    case live
    /// An irreversible action that destroys retained state. Drawn as an outline rather than a fill
    /// so it never competes with the committing action beside it, in the destructive role's own
    /// colour so it cannot be mistaken for a secondary.
    case destructive
}

struct CoachWorldActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let role: CoachWorldActionRole
    let palette: CoachWorldTokens.Palette

    func makeBody(configuration: Configuration) -> some View {
        let appearance = self.appearance
        let controlShape = CoachWorldCutCorner.action

        configuration.label
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
                controlShape.stroke(
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
        case .destructive:
            // Outlined, not filled: a destructive action must be reachable and unmistakable
            // without out-shouting the committing action it sits beside.
            return (
                Color.clear,
                palette.actionDestructive.color,
                palette.actionDestructive.color
            )
        }
    }
}

struct CoachWorldRouteButton: View {
    let title: String
    let isCurrent: Bool
    let palette: CoachWorldTokens.Palette
    /// Selection furniture speaks in the programme's colour when a screen has one. Defaulting to
    /// the tier token keeps every screen that has not been given an identity unchanged.
    var selection: CoachWorldTokens.ColorValue?
    let action: () -> Void

    private var selectionColour: CoachWorldTokens.ColorValue { selection ?? palette.collegeIdentity }

    var body: some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
        .tracking(CoachWorldTokens.TypeRole.microLabelTracking)
        .frame(
            maxWidth: .infinity,
            minHeight: CoachWorldTokens.Shape.minimumTarget
        )
        .padding(.horizontal, CoachWorldTokens.Space.xxs)
        .background {
            if isCurrent {
                CoachWorldCutCorner.row
                    .fill(selectionColour.color.opacity(0.15))
            }
        }
        .overlay(alignment: .bottom) {
            if isCurrent {
                Rectangle()
                    .fill(selectionColour.color)
                    .frame(height: 3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

private struct CoachWorldFloodlitPanelModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let fill: Color
    let border: Color
    let depth: CoachWorldFloodlitPanelDepth

    func body(content: Content) -> some View {
        let shape = CoachWorldCutCorner.panel
        content
            .background {
                if reduceTransparency {
                    shape.fill(fill)
                } else {
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay(shape.fill(fill.opacity(depth.opacity)))
                        .overlay {
                            LinearGradient(
                                colors: [.white.opacity(0.10), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                            .clipShape(shape)
                        }
                }
            }
            .overlay {
                shape.stroke(border, lineWidth: CoachWorldTokens.Shape.hairline)
            }
            .clipShape(shape)
    }
}

extension View {
    func coachWorldFloodlitPanel(
        fill: Color,
        border: Color,
        depth: CoachWorldFloodlitPanelDepth = .glass
    ) -> some View {
        modifier(CoachWorldFloodlitPanelModifier(fill: fill, border: border, depth: depth))
    }
}
