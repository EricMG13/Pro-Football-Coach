import SwiftUI

/// Family 15. Last result, the plan that went with it, and the observed opponent rates.
///
/// Density budget (`04` §4.5): dominant object is the score and opponent; the recorded plan is
/// the one secondary region; zero verdict lines (the review holds rates, not a staff sermon).
public struct AftermathView: View {
    public let model: AftermathReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: AftermathReadModel,
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
                        current: .aftermath,
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
            resultCard.frame(maxWidth: .infinity)
            reviewCard.frame(width: 240)
        }
        .padding(CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: CoachWorldTokens.Space.xs) {
                resultCard
                reviewCard
                strip
                CoachWorldOfficeRoutes(
                    current: .aftermath,
                    palette: palette,
                    isAccessibilitySize: true,
                    onNavigate: onNavigate
                )
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    @ViewBuilder
    private var resultCard: some View {
        if !model.hasResult {
            CoachWorldEmptyState(
                title: "No match played yet",
                systemImage: "list.number",
                description: "Aftermath opens after a recorded result. Week one of a new career has not played a game.",
                palette: palette
            )
            .coachWorldDeskSurface(
                fill: palette.work.color,
                border: palette.contentQuiet.color.opacity(0.45)
            )
            .accessibilitySortPriority(100)
        } else {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                Text((model.gameWeekLabel ?? model.frame.weekLabel).uppercased())
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                Text(resultHeadline)
                    .font(CoachWorldTokens.TypeRole.display.weight(.black))
                    .monospacedDigit()
                Text(matchupLine)
                    .font(CoachWorldTokens.TypeRole.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(model.isHome == true ? "Home" : "Away")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                Spacer(minLength: 0)
            }
            .padding(CoachWorldTokens.Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .coachWorldDeskSurface(
                fill: palette.work.color,
                border: palette.contentQuiet.color.opacity(0.45)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(resultHeadline). \(matchupLine)")
            .accessibilitySortPriority(100)
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("RECORDED PLAN")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            if let runPass = model.runPass, let tempo = model.tempo, let pressure = model.pressure {
                Text("\(runPass.rawValue) · \(tempo.rawValue) · \(pressure.rawValue)")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No plan was stored for that game.")
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            if let passRate = model.opponentPassRate {
                CoachWorldMeter(
                    title: "Opponent pass share",
                    value: passRate,
                    maximum: 100,
                    unit: "%",
                    palette: palette
                )
            }
            if let turnover = model.opponentTurnoverRate {
                CoachWorldMeter(
                    title: "Opponent turnover rate",
                    value: turnover,
                    maximum: 100,
                    unit: "%",
                    palette: palette
                )
            }
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldDeskSurface(
            fill: palette.raised.color.opacity(0.45),
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(30)
    }

    private var resultHeadline: String {
        guard let ours = model.ourScore, let theirs = model.theirScore else { return "" }
        if ours > theirs { return "W  \(ours)–\(theirs)" }
        if ours < theirs { return "L  \(ours)–\(theirs)" }
        return "T  \(ours)–\(theirs)"
    }

    private var matchupLine: String {
        let them = model.opponent?.name ?? "Opponent"
        return model.isHome == true
            ? "\(model.frame.team.name) vs \(them)"
            : "\(model.frame.team.name) at \(them)"
    }
}
