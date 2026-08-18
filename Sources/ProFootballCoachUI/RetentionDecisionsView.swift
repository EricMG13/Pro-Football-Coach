import SwiftUI
import FootballSimCore

public struct RetentionDecisionsView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: CollegeOffseasonReadModel
    public let statusMessage: String?
    public let onCommit: (CoachWorldIntentID) -> Void
    public let onContinue: () -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: CollegeOffseasonReadModel, statusMessage: String? = nil,
                onCommit: @escaping (CoachWorldIntentID) -> Void,
                onContinue: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onContinue = onContinue
        self.onClose = onClose
    }

    public var body: some View {
        CollegeOffseasonView(model: model, title: "RETENTION DECISIONS", statusMessage: statusMessage,
                              onCommit: onCommit, onContinue: onContinue, onClose: onClose)
            .floodlitChrome(chrome, onNavigate: onNavigateChrome)
            .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
