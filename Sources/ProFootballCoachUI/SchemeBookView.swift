import SwiftUI
import FootballSimCore

public struct SchemeBookView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: GamePlanReadModel
    public let statusMessage: String?
    public let onSelect: (TacticalPlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: GamePlanReadModel,
        statusMessage: String? = nil,
        onSelect: @escaping (TacticalPlan) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        GamePlanView(
            model: model,
            title: "SCHEME BOOK",
            statusMessage: statusMessage,
            onSelect: onSelect,
            onClose: onClose
        )
        .floodlitChrome(chrome, onNavigate: onNavigateChrome)
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
