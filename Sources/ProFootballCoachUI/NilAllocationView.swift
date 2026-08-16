import SwiftUI
import FootballSimCore

public struct NilAllocationView: View {
    public let model: CollegeOffseasonReadModel
    public let statusMessage: String?
    public let onCommit: (CoachWorldIntentID) -> Void
    public let onContinue: () -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: CollegeOffseasonReadModel, statusMessage: String? = nil,
                onCommit: @escaping (CoachWorldIntentID) -> Void,
                onContinue: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onContinue = onContinue
        self.onClose = onClose
    }

    public var body: some View {
        CollegeOffseasonView(model: model, title: "NIL ALLOCATION", statusMessage: statusMessage,
                              onCommit: onCommit, onContinue: onContinue, onClose: onClose)
            .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
