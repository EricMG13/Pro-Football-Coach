import SwiftUI
import FootballSimCore

/// The controlled draft clock, reusing the authoritative pro-market reducer.
public struct DraftRoomView: View {
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
        Group {
            if model.phase == .draft {
                ProOffseasonView(
                    model: model,
                    title: "DRAFT ROOM",
                    statusMessage: statusMessage,
                    onAction: onAction,
                    onClose: onClose
                )
            } else {
                ContentUnavailableView(
                    "Draft room is closed",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("The controlled draft clock is not active in this phase.")
                )
            }
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
