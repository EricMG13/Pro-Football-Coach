import SwiftUI

/// Entry surface for restoring a career or starting a new one.
public struct TitleContinueView: View {
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

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            content.accessibilitySortPriority(100)
        } else {
            content.accessibilitySortPriority(100)
        }
    }

    private var content: some View {
        VStack(spacing: CoachWorldTokens.Space.md) {
            Text("Pro Football Coach")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            if let failure {
                Text(failure)
                    .font(CoachWorldTokens.TypeRole.body)
                    .multilineTextAlignment(.center)
            }
            if isStarting {
                ProgressView("Building the world")
            } else if isRestoring {
                ProgressView("Loading career")
            } else if recoveryRequired {
                Button("Retry restore", action: onRetry)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                Button("Use backup", action: onUseBackup)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                Button("Replace with a new career", action: onNewCareer)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            } else {
                Button("New career", action: onNewCareer)
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            Button("Settings & accessibility", action: onSettings)
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(CoachWorldTokens.Space.xl)
    }
}
