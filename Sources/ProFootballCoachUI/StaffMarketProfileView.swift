import SwiftUI

public struct StaffMarketProfileView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


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
            .floodlitChrome(chrome, onNavigate: onNavigateChrome)
            .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
