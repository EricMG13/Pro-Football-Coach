import SwiftUI

/// Family 1. The durable boundary: no career, a failed save, or a world being built.
///
/// Density budget (`04` §4.5): one dominant object (the career boundary), no secondary regions,
/// zero status glyphs, zero verdict lines, one tap to start.
public struct TitleContinueView: View {
    public let model: TitleContinueReadModel
    public let onNewCareer: () -> Void
    public let onContinueCareer: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: TitleContinueReadModel,
        onNewCareer: @escaping () -> Void,
        onContinueCareer: @escaping () -> Void
    ) {
        self.model = model
        self.onNewCareer = onNewCareer
        self.onContinueCareer = onContinueCareer
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                standardLayout
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private var standardLayout: some View {
        HStack(spacing: CoachWorldTokens.Space.xl) {
            identityColumn.frame(maxWidth: .infinity, alignment: .leading)
            actionsColumn.frame(width: 280, alignment: .leading)
        }
        .padding(CoachWorldTokens.Space.xl)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.lg) {
                identityColumn
                actionsColumn
            }
            .padding(CoachWorldTokens.Space.md)
        }
    }

    private var identityColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("PRO FOOTBALL COACH")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text("One coach. College to the pros.")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(boundaryCopy)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(100)
    }

    private var actionsColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            if let failure = model.failure {
                CoachWorldErrorBanner(message: failure, palette: palette)
            }
            if model.isStarting {
                ProgressView("Building the world")
                    .frame(
                        maxWidth: .infinity,
                        minHeight: CoachWorldTokens.Shape.minimumTarget,
                        alignment: .leading
                    )
            } else {
                if model.hasExistingSave {
                    Button("Continue career", action: onContinueCareer)
                        .buttonStyle(CoachWorldActionButtonStyle(role: .live, palette: palette))
                        .frame(maxWidth: .infinity)
                }
                Button("New career", action: onNewCareer)
                    .buttonStyle(CoachWorldActionButtonStyle(
                        role: model.hasExistingSave ? .secondary : .primary,
                        palette: palette
                    ))
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilitySortPriority(80)
    }

    private var boundaryCopy: String {
        if model.isStarting {
            return "The league is being generated from a fixed seed so every tester plays the same world."
        }
        if model.hasExistingSave {
            return "A career is on this device. Continue it, or start a new one and replace it."
        }
        return "Start a career. The first job is the lowest-prestige programme in a generated college world."
    }
}
