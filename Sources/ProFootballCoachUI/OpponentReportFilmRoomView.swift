import SwiftUI

/// Canonical screen-family entry for the observer-scoped opponent report / film room.
/// The existing film composition remains the single implementation of the evidence surface.
public struct OpponentReportFilmRoomView: View {
    public let model: OpponentFilmReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: OpponentFilmReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void, onContinue: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            film.accessibilitySortPriority(100)
        } else {
            film.accessibilitySortPriority(100)
        }
    }

    private var film: some View {
        OpponentFilmView(
            model: model,
            statusMessage: statusMessage,
            onClose: onClose,
            onContinue: onContinue
        )
    }
}
