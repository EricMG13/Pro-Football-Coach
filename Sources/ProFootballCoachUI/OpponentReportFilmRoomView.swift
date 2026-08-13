import SwiftUI

/// Family 10. Film Room register: observed tendencies, not a staff sermon.
///
/// Density budget (`04` §4.5): dominant object is the observed pass/turnover pair; opponent
/// identity is the one secondary region; zero verdict lines (G-02 unbuilt).
public struct OpponentReportFilmRoomView: View {
    public let model: OpponentReportReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: OpponentReportReadModel,
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
                        current: .opponentReportFilmRoom,
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
            identityRail.frame(width: 200)
            evidence.frame(maxWidth: .infinity)
        }
        .padding(CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: CoachWorldTokens.Space.xs) {
                evidence
                identityRail
                strip
                CoachWorldOfficeRoutes(
                    current: .opponentReportFilmRoom,
                    palette: palette,
                    isAccessibilitySize: true,
                    onNavigate: onNavigate
                )
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var identityRail: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("FILM ROOM · OPPONENT")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.opponent?.name ?? "Bye week")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            if let venue = model.venue {
                Text(venue.name)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            if let observed = model.observedThroughLabel {
                Text("Observed through \(observed)")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.semibold))
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Text("Staff interpretation is not shown. The engine does not yet own a named-staff verdict or a confidence band for opponent film.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(40)
    }

    @ViewBuilder
    private var evidence: some View {
        if model.opponent == nil {
            CoachWorldEmptyState(
                title: "No opponent this week",
                systemImage: "list.number",
                description: "A bye has no film. The schedule is the authority; this screen does not invent a matchup.",
                palette: palette
            )
            .coachWorldDeskSurface(
                fill: palette.work.color,
                border: palette.contentQuiet.color.opacity(0.45)
            )
            .accessibilitySortPriority(100)
        } else if model.passRate == nil {
            CoachWorldEmptyState(
                title: "No film recorded yet",
                systemImage: "list.number",
                description: "Opponent tendencies are written when a scouting snapshot is taken. Until then the rates stay blank rather than guessed.",
                palette: palette
            )
            .coachWorldDeskSurface(
                fill: palette.work.color,
                border: palette.contentQuiet.color.opacity(0.45)
            )
            .accessibilitySortPriority(100)
        } else {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.lg) {
                Text("OBSERVED TENDENCIES")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                CoachWorldMeter(
                    title: "Pass share",
                    value: model.passRate ?? 0,
                    maximum: 100,
                    unit: "%",
                    palette: palette
                )
                CoachWorldMeter(
                    title: "Turnovers per four games",
                    value: model.turnoverRate ?? 0,
                    maximum: 100,
                    unit: "%",
                    palette: palette
                )
                Text("These are recorded shares, not a judgement about what they mean.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                Spacer(minLength: 0)
            }
            .padding(CoachWorldTokens.Space.sm)
            .coachWorldDeskSurface(
                fill: palette.work.color,
                border: palette.contentQuiet.color.opacity(0.45)
            )
            .accessibilitySortPriority(100)
        }
    }
}
