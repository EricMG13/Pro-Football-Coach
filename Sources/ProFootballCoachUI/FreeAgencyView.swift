import SwiftUI
import FootballSimCore

public struct FreeAgencyView: View {
    public let model: ProOffseasonReadModel
    public let statusMessage: String?
    public let onAction: (ProMarketAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: ProOffseasonReadModel,
        statusMessage: String? = nil,
        onAction: @escaping (ProMarketAction) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    public var body: some View {
        ProOffseasonView(
            model: model,
            title: "FREE AGENCY",
            statusMessage: statusMessage,
            onAction: onAction,
            onClose: onClose
        )
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
