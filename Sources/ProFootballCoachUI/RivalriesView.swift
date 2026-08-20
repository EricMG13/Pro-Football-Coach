import SwiftUI

public struct RivalriesView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


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
        LegacyHistoryView(model: model, focus: .rivalries, statusMessage: statusMessage,
                          onClose: onClose, onNavigate: onNavigate)
            .floodlitChrome(chrome, onNavigate: onNavigateChrome)
            .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
            .accessibilitySortPriority(100)
    }
}
