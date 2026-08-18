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
    public let onRetry: () -> Void
    public let onUseBackup: () -> Void
    public let onNewCareer: () -> Void
    public let onSettings: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(failure: String? = nil, isStarting: Bool = false, isRestoring: Bool = false,
                recoveryRequired: Bool = false, onRetry: @escaping () -> Void,
                onUseBackup: @escaping () -> Void, onNewCareer: @escaping () -> Void,
                onSettings: @escaping () -> Void) {
        self.failure = failure
        self.isStarting = isStarting
        self.isRestoring = isRestoring
        self.recoveryRequired = recoveryRequired
        self.onRetry = onRetry
        self.onUseBackup = onUseBackup
        self.onNewCareer = onNewCareer
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
}
