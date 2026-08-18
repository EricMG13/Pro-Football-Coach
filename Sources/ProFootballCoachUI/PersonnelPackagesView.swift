import SwiftUI
import FootballSimCore

public struct PersonnelPackagesView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: DepthChartReadModel
    public let statusMessage: String?
    public let onSelect: (PersonnelPlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: DepthChartReadModel,
        statusMessage: String? = nil,
        onSelect: @escaping (PersonnelPlan) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        DepthChartView(
            model: model,
            title: "PERSONNEL PACKAGES",
            statusMessage: statusMessage,
            onSelect: onSelect,
            onClose: onClose
        )
        .floodlitChrome(chrome, onNavigate: onNavigateChrome)
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
