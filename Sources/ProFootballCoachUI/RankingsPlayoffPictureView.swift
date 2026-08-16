import SwiftUI

/// Registry entry for rankings and the live playoff picture, backed by the shared competition snapshot.
public struct RankingsPlayoffPictureView: View {
    public let model: CompetitionOverviewReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: CompetitionOverviewReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void, onContinue: @escaping () -> Void,
                onSelectTeam: @escaping (UUID) -> Void = { _ in }) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
        self.onSelectTeam = onSelectTeam
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            content.accessibilitySortPriority(100)
        } else {
            content.accessibilitySortPriority(100)
        }
    }

    private var content: some View {
        CompetitionOverviewView(model: model, focus: .rankingsPlayoffPicture,
                                statusMessage: statusMessage, onClose: onClose,
                                onContinue: onContinue, onSelectTeam: onSelectTeam)
    }
}
