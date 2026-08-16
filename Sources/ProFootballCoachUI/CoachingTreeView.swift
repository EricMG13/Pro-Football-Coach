import SwiftUI

public struct CoachingTreeView: View {
    public let model: LegacyHistoryReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: LegacyHistoryReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void, onNavigate: @escaping (CoachWorldScreenID) -> Void) {
        self.model = model; self.statusMessage = statusMessage; self.onClose = onClose; self.onNavigate = onNavigate
    }

    public var body: some View {
        LegacyHistoryView(model: model, focus: .coachingTree, statusMessage: statusMessage,
                          onClose: onClose, onNavigate: onNavigate)
            .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
            .accessibilitySortPriority(100)
    }
}
