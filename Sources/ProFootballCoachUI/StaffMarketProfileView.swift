import SwiftUI

public struct StaffMarketProfileView: View {
    public let model: StaffRoomReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: StaffRoomReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
    }

    public var body: some View {
        StaffRoomView(model: model, title: "STAFF MARKET & PROFILE",
                      statusMessage: statusMessage, onClose: onClose)
            .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
