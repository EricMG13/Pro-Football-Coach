import SwiftUI

public struct PromotionDecisionView: View {
    public let model: CareerHubReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onAcceptOpportunity: (String) -> Void
    public let onResign: () -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: CareerHubReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onAcceptOpportunity: @escaping (String) -> Void = { _ in },
        onResign: @escaping () -> Void = {},
        onContinue: @escaping () -> Void = {}
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onNavigate = onNavigate
        self.onAcceptOpportunity = onAcceptOpportunity
        self.onResign = onResign
        self.onContinue = onContinue
    }

    public var body: some View {
        let content = CareerHubView(
            model: model,
            statusMessage: statusMessage,
            onClose: onClose,
            focus: .promotionDecision,
            onNavigate: onNavigate,
            onAcceptOpportunity: onAcceptOpportunity,
            onResign: onResign,
            onContinue: onContinue
        )
        if dynamicTypeSize.isAccessibilitySize {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilitySortPriority(100)
        } else {
            content
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilitySortPriority(100)
        }
    }
}
