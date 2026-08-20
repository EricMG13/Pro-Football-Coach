import SwiftUI

/// Registry entry for rankings and the live playoff picture, backed by the shared competition snapshot.
public struct RankingsPlayoffPictureView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: CompetitionOverviewReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

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
        // Both arms of the old AX5 branch here were character-for-character identical -- an
        // accessibility-size composition that was never actually decided (S-7, 2026-08-19 review).
        // `content` delegates its whole composition to CompetitionOverviewView, which is where AX5
        // is genuinely handled; collapsed to the one statement both arms already agreed on.
        content.accessibilitySortPriority(100)
    }

    private var content: some View {
        CompetitionOverviewView(model: model, focus: .rankingsPlayoffPicture,
                                statusMessage: statusMessage, onClose: onClose,
                                onContinue: onContinue, onSelectTeam: onSelectTeam)
            .floodlitChrome(chrome, onNavigate: onNavigateChrome)
    }
}
