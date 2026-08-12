import SwiftUI

enum CoachWorldActionRole {
    case primary
    case secondary
    case live
}

struct CoachWorldActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let role: CoachWorldActionRole
    let palette: CoachWorldTokens.Palette

    func makeBody(configuration: Configuration) -> some View {
        let appearance = self.appearance
        let controlShape = RoundedRectangle(
            cornerRadius: CoachWorldTokens.Shape.controlRadius
        )

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
        }
    }
}

struct CoachWorldRouteButton: View {
    let title: String
    let isCurrent: Bool
    let palette: CoachWorldTokens.Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
        .frame(
            maxWidth: .infinity,
            minHeight: CoachWorldTokens.Shape.minimumTarget
        )
        .padding(.horizontal, CoachWorldTokens.Space.xxs)
        .background(isCurrent ? palette.collegeIdentity.color.opacity(0.16) : Color.clear)
        .overlay(alignment: .bottom) {
            if isCurrent {
                Rectangle()
                    .fill(palette.collegeIdentity.color)
                    .frame(height: 3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

private struct CoachWorldDeskSurfaceModifier: ViewModifier {
    let fill: Color
    let border: Color

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius)
                    .stroke(border, lineWidth: CoachWorldTokens.Shape.hairline)
            }
            .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius))
    }
}

extension View {
    func coachWorldDeskSurface(fill: Color, border: Color) -> some View {
        modifier(CoachWorldDeskSurfaceModifier(fill: fill, border: border))
    }
}
