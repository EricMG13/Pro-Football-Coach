import SwiftUI
import FootballSimCore

public struct RosterCutsTransactionsView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


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
        ProManagementView(model: model, title: "ROSTER CUTS & TRANSACTIONS", canonicalID: 36,
                          statusMessage: statusMessage, onAction: onAction, onClose: onClose)
            .floodlitChrome(chrome, onNavigate: onNavigateChrome)
            .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
