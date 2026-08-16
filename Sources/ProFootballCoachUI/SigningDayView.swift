import SwiftUI
import FootballSimCore

public struct SigningDayView: View {
    public let model: CollegeOffseasonReadModel
    public let statusMessage: String?
    public let onCommit: (CoachWorldIntentID) -> Void
    public let onContinue: () -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: CollegeOffseasonReadModel,
        statusMessage: String? = nil,
        onCommit: @escaping (CoachWorldIntentID) -> Void,
        onContinue: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onContinue = onContinue
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            if model.cyclePhase == .signing {
                CollegeOffseasonView(
                    model: model,
                    title: "SIGNING DAY",
                    statusMessage: statusMessage,
                    onCommit: onCommit,
                    onContinue: onContinue,
                    onClose: onClose
                )
            } else {
                ContentUnavailableView(
                    "Signing day is closed",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("The signing period is not active in this phase.")
                )
            }
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
