import SwiftUI

/// Family 9. Commitments with cost. Correspondence is empty until an inbox system exists.
///
/// Density budget (`04` §4.5): dominant object is the agenda; desk mail is a secondary empty
/// region; zero verdict lines; at most one status glyph per row from the obligation class.
public struct InboxView: View {
    public let model: InboxReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: InboxReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    strip
                    CoachWorldOfficeRoutes(
                        current: .inbox,
                        palette: palette,
                        isAccessibilitySize: false,
                        onNavigate: onNavigate
                    )
                    standardLayout
                }
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private var strip: some View {
        CoachWorldWorldStrip(
            team: model.frame.team,
            contextLine: model.frame.contextLine,
            statusMessage: statusMessage,
            currentWorldRoute: .coachingHQ,
            canAdvance: model.frame.canAdvance,
            mandatoryDueCount: model.frame.mandatoryDueCount,
            palette: palette,
            isAccessibilitySize: dynamicTypeSize.isAccessibilitySize,
            onContinue: onContinue,
            onNavigate: onNavigate
        )
    }

    private var standardLayout: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            agenda.frame(maxWidth: .infinity)
            mail.frame(width: 220)
        }
        .padding(CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: CoachWorldTokens.Space.xs) {
                agenda
                mail
                strip
                CoachWorldOfficeRoutes(
                    current: .inbox,
                    palette: palette,
                    isAccessibilitySize: true,
                    onNavigate: onNavigate
                )
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var agenda: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text("COMMITMENTS")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                Spacer()
                Text("\(model.frame.mandatoryDueCount) DUE")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.stateWarning.color)
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }

            if model.commitments.isEmpty {
                CoachWorldEmptyState(
                    title: "No commitments this week",
                    systemImage: "checkmark.circle",
                    description: "Nothing queued is blocking the week advance.",
                    palette: palette
                )
            } else {
                ForEach(model.commitments) { item in
                    CoachWorldAgendaRow(item: item, palette: palette) {
                        onNavigate(.coachingHQ)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(100)
    }

    private var mail: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("CORRESPONDENCE")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
                .padding(.horizontal, CoachWorldTokens.Space.sm)
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .overlay(alignment: .bottom) { CoachWorldHairline(palette: palette) }
            CoachWorldEmptyState(
                title: "No mail",
                systemImage: "list.number",
                description: "There is no inbound correspondence system yet. Commitments on the left are the queued decisions that actually block the week.",
                palette: palette
            )
        }
        .coachWorldDeskSurface(
            fill: palette.raised.color.opacity(0.45),
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(30)
    }
}
