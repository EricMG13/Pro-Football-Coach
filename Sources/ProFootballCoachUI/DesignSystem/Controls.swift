import SwiftUI

/// Registry 2 — the committing action.
///
/// Gold is allowed to be a field here, and only here: this is the one thing on screen that moves
/// the game forward, so it earns the light. Everything else that looks interactive is outlined
/// (`04` §5). A filled control inks with the ground, never with `content.primary`, which measures
/// 1.51 on the gold fill.
///
/// **The action is required.** Floodlit defaulted it to `{}` and then shipped five screens where no
/// control did anything; a dead button that compiles is worse than one that does not.
public struct GoButton: View {
    public enum Kind { case solid, ghost }

    public enum Size {
        case regular, compact

        var height: CGFloat {
            self == .regular
                ? CoachWorldTokens.Control.actionHeight
                : CoachWorldTokens.Control.actionCompactHeight
        }

        var textSize: CGFloat {
            self == .regular
                ? CoachWorldTokens.Control.actionTextSize
                : CoachWorldTokens.Control.actionCompactTextSize
        }

        var inset: CGFloat {
            self == .regular
                ? CoachWorldTokens.Control.actionInset
                : CoachWorldTokens.Control.actionCompactInset
        }
    }

    @Environment(\.coachWorldPalette) private var palette
    @Environment(\.coachWorldFills) private var fills
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    private let title: String
    private let kind: Kind
    private let size: Size
    private let spansWidth: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        kind: Kind = .solid,
        size: Size = .regular,
        spansWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.kind = kind
        self.size = size
        self.spansWidth = spansWidth
        self.action = action
    }

    /// One shape for both sizes. Floodlit carried a second, tighter cut for the compact form;
    /// `04` §6.3 states exactly one action shape, and a second undocumented one is the drift the
    /// registry exists to prevent.
    private var shape: CutCorner { .action }

    private var textSize: CGFloat { size.textSize * scale }

    public var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(CoachWorldTokens.TypeRole.display(textSize))
                .tracking(textSize * CoachWorldTokens.Control.actionTracking)
                .foregroundStyle(ink)
                .lineLimit(1)
                .padding(.horizontal, size.inset)
                .frame(minHeight: max(size.height * scale, CoachWorldTokens.Shape.minimumTarget))
                .frame(maxWidth: spansWidth ? .infinity : nil)
                .background { field }
                .shadow(color: glow, radius: CoachWorldTokens.Control.actionGlowRadius,
                        y: CoachWorldTokens.Control.actionGlowOffsetY)
        }
        .buttonStyle(.plain)
    }

    private var ink: Color {
        kind == .solid ? fills.onFill.color : palette.contentPrimary.color
    }

    private var glow: Color {
        kind == .solid
            ? palette.actionPrimary.color.opacity(CoachWorldTokens.Control.actionGlowOpacity)
            : .clear
    }

    @ViewBuilder private var field: some View {
        if kind == .solid {
            shape.fill(LinearGradient(
                colors: [
                    CoachWorldTokens.Gauge.arcLight.color,
                    palette.actionPrimary.color,
                    CoachWorldTokens.Gauge.arcDeep.color
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        } else {
            shape.fill(CoachWorldTokens.Control.ghostFill.color)
                .overlay(shape.strokeBorder(
                    CoachWorldTokens.Glass.edge.color,
                    lineWidth: CoachWorldTokens.Shape.hairline
                ))
        }
    }
}

/// Registry 33 — a recruiting star rating, drawn as blades rather than clip-art stars.
///
/// `04` §6.6's Rating-marks class, cap 1, and it is **always beside its printed figure**: the
/// blades are a second reading, so the row prints "4 stars" and the marks illustrate it.
public struct StarRating: View {
    @Environment(\.coachWorldPalette) private var palette

    private let value: Int
    private let total: Int
    private let height: CGFloat

    public init(_ value: Int, of total: Int = 5, height: CGFloat = CoachWorldTokens.Control.bladeHeight) {
        self.value = value
        self.total = total
        self.height = height
    }

    public var body: some View {
        HStack(spacing: CoachWorldTokens.Control.bladeGap) {
            ForEach(0..<total, id: \.self) { index in
                Blade()
                    .fill(index < value ? AnyShapeStyle(earned) : AnyShapeStyle(unearned))
                    .frame(width: height * CoachWorldTokens.Control.bladeAspect, height: height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) of \(total) stars")
    }

    private var earned: LinearGradient {
        LinearGradient(
            colors: [CoachWorldTokens.Gauge.arcLight.color, palette.actionPrimary.color],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var unearned: Color { CoachWorldTokens.Control.bladeEmpty.color }
}

struct Blade: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.38))
        path.closeSubpath()
        return path
    }
}

/// Registry 34 — the club mark as a depicted object.
///
/// **Takes its colours rather than owning them.** Floodlit hard-coded one club's field and accent;
/// every mark in this product is generated per programme, so the colours arrive from
/// `CoachWorldTeamIdentity` and this type only draws. It is identity furniture under `04` §5, not
/// a vocabulary item the player learns, which is why §6.6 does not count it.
///
/// The boundary is not optional: `04` §6.1 makes a hairline mandatory on every team-colour fill,
/// because generated colour cannot be assumed to clear the non-text floor against any surface.
public struct Pennant: View {
    private let field: Color
    private let stripe: Color
    private let dot: Color?
    private let width: CGFloat
    private let height: CGFloat

    public init(
        field: Color,
        stripe: Color,
        dot: Color? = nil,
        width: CGFloat = CoachWorldTokens.Control.pennantWidth,
        height: CGFloat = CoachWorldTokens.Control.pennantHeight
    ) {
        self.field = field
        self.stripe = stripe
        self.dot = dot
        self.width = width
        self.height = height
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            field
            Rectangle().fill(stripe).frame(width: width * 0.3)
            if let dot {
                Circle()
                    .fill(dot)
                    .frame(width: width * 0.3, height: width * 0.3)
                    .offset(x: width * 0.5, y: height * 0.33)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .overlay(Rectangle().strokeBorder(
            CoachWorldTokens.Control.markBoundary.color,
            lineWidth: CoachWorldTokens.Shape.hairline
        ))
        .accessibilityHidden(true)
    }
}

/// Registry 35 — timeouts remaining. A filled mark is one in hand.
///
/// `04` §6.6's Broadcast-marks class (cap 3, alongside the possession wedge and the key-moment
/// mark): each carries a printed or spoken value beside it and never counts alone.
public struct TimeoutMarks: View {
    @Environment(\.coachWorldPalette) private var palette

    private let remaining: Int
    private let total: Int
    private let tint: Color?

    public init(remaining: Int, total: Int = 3, tint: Color? = nil) {
        self.remaining = remaining
        self.total = total
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: CoachWorldTokens.Control.timeoutGap) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < remaining
                          ? (tint ?? palette.contentPrimary.color)
                          : CoachWorldTokens.Control.timeoutSpent.color)
                    .frame(
                        width: CoachWorldTokens.Control.timeoutMarkWidth,
                        height: CoachWorldTokens.Control.timeoutMarkHeight
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(remaining) of \(total) timeouts remaining")
    }
}
