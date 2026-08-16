import SwiftUI
import FootballSimCore

public struct CapContractsView: View {
    public let model: ProManagementReadModel
    public let statusMessage: String?
    public let onAction: (ProManagementAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: ProManagementReadModel, statusMessage: String? = nil,
                onAction: @escaping (ProManagementAction) -> Void,
                onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    public var body: some View {
        ProManagementView(model: model, title: "CAP & CONTRACTS",
                          statusMessage: statusMessage, onAction: onAction, onClose: onClose)
            .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
