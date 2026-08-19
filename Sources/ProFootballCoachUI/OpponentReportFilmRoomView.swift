import SwiftUI

/// Canonical screen-family entry for the observer-scoped opponent report / film room.
/// The existing film composition remains the single implementation of the evidence surface.
public struct OpponentReportFilmRoomView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). This surface delegates its whole
    /// composition, so it passes the chrome straight through to the view that draws it rather than
    /// wrapping a second stage around one that already has one.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

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
        film
            .frame(
                maxWidth: .infinity,
                alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center
            )
            .accessibilitySortPriority(100)
    }

    private var film: some View {
        OpponentFilmView(
            model: model,
            statusMessage: statusMessage,
            onClose: onClose,
            onContinue: onContinue
        )
        .floodlitChrome(chrome, onNavigate: onNavigateChrome)
    }
}
