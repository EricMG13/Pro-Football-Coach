import SwiftUI
import FootballSimCore

/// The controlled draft clock, reusing the authoritative pro-market reducer.
public struct DraftRoomView: View {
    public let model: ProOffseasonReadModel
    public let statusMessage: String?
    public let onAction: (ProMarketAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: ProOffseasonReadModel,
        statusMessage: String? = nil,
        onAction: @escaping (ProMarketAction) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        Group {
            if model.phase == .draft {
                ProOffseasonView(
                    model: model,
                    title: "DRAFT ROOM",
                    statusMessage: statusMessage,
                    onAction: onAction,
                    onClose: onClose
                )
            } else {
                // The closed branch draws its own world: it does not delegate, so it needs the
                // stage the delegated branch inherits from ProOffseasonView.
                CoachWorldFloodlitStage(palette: palette) {
                    CoachWorldSystemState(
                        .empty(
                            "Draft room is closed. The controlled draft clock is not "
                                + "active in this phase."
                        ),
                        palette: palette
                    )
                }
            }
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
