import SwiftUI

/// Entry surface for restoring a career or starting a new one.
public struct TitleContinueView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let failure: String?
    public let isStarting: Bool
    public let isRestoring: Bool
    public let recoveryRequired: Bool
    /// A career a successful load already restored, waiting on the coach's own confirmation to
    /// continue into it rather than being jumped into automatically -- the durable-boundary half
    /// of this surface's job, `02` section 9's "current career and durable boundary."
    public let restoredCareer: CareerHubReadModel?
    public let onRetry: () -> Void
    public let onUseBackup: () -> Void
    public let onNewCareer: () -> Void
    public let onContinue: () -> Void
    public let onSettings: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(failure: String? = nil, isStarting: Bool = false, isRestoring: Bool = false,
                recoveryRequired: Bool = false, restoredCareer: CareerHubReadModel? = nil,
                onRetry: @escaping () -> Void, onUseBackup: @escaping () -> Void,
                onNewCareer: @escaping () -> Void, onContinue: @escaping () -> Void = {},
                onSettings: @escaping () -> Void) {
        self.failure = failure
        self.isStarting = isStarting
        self.isRestoring = isRestoring
        self.recoveryRequired = recoveryRequired
        self.restoredCareer = restoredCareer
        self.onRetry = onRetry
        self.onUseBackup = onUseBackup
        self.onNewCareer = onNewCareer
        self.onContinue = onContinue
        self.onSettings = onSettings
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            content
        }
        .accessibilitySortPriority(100)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
            Text("Pro Football Coach")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            if let failure {
                Text(failure)
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.stateNegative.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if isStarting {
                // Indeterminate by design: 04 section 7 forbids invented percentage progress.
                ProgressView("Building the world")
                    .tint(palette.actionPrimary.color)
            } else if isRestoring {
                ProgressView("Loading career")
                    .tint(palette.actionPrimary.color)
            } else if recoveryRequired {
                recoveryActions
            } else if let restoredCareer {
                careerSummary(restoredCareer)
            } else {
                Button("New career", action: onNewCareer)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            Button("Settings & accessibility", action: onSettings)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(CoachWorldTokens.Space.xl)
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
    }

    /// Restore failed. Retry is the committing action because it is the one that loses nothing;
    /// replacing the save is destructive and irreversible, so it is demoted to the destructive role
    /// and carries the consequence sentence above it rather than after the tap.
    private var recoveryActions: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Button("Retry restore", action: onRetry)
                .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            Button("Use backup", action: onUseBackup)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            Text("Starting over deletes this career and every season in it. There is no undo.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Button("Delete and start over", action: onNewCareer)
                .buttonStyle(CoachWorldActionButtonStyle(role: .destructive, palette: palette))
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .accessibilityHint(
                    "Starting over deletes this career and every season in it. There is no undo."
                )
        }
    }

    /// The current career and the durable boundary, both on the surface whose named job is
    /// exactly this (`02` section 9) -- restoreExistingCareer used to compute this same data and
    /// jump straight past it into gameplay; this is what the coach sees instead.
    private func careerSummary(_ career: CareerHubReadModel) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text(career.coach.name.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.title, weight: .bold)
            if let job = career.currentJob {
                Text("\(job.tier) \u{00B7} \(job.team.name) \u{00B7} since \(job.started)")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                Text("Between appointments")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Text("\(career.status) \u{00B7} \(careerHistoryLabel(career))")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
            Button("Continue", action: onContinue)
                .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            Text("Starting over deletes this career and every season in it. There is no undo.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Button("Start a new career instead", action: onNewCareer)
                .buttonStyle(CoachWorldActionButtonStyle(role: .destructive, palette: palette))
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .accessibilityHint(
                    "Starting over deletes this career and every season in it. There is no undo."
                )
        }
    }

    private func careerHistoryLabel(_ career: CareerHubReadModel) -> String {
        let count = career.history.count
        if count == 0 { return "this is the first appointment" }
        return count == 1 ? "one appointment before this" : "\(count) appointments before this"
    }
}
