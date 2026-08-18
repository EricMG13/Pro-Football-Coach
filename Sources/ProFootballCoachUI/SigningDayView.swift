import SwiftUI
import FootballSimCore

public struct SigningDayView: View, CoachWorldChromedSurface {
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

    public init(
        model: CollegeOffseasonReadModel,
        statusMessage: String? = nil,
        onCommit: @escaping (CoachWorldIntentID) -> Void,
        onContinue: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onContinue = onContinue
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        Group {
            if model.cyclePhase == .signing {
                CollegeOffseasonView(
                    model: model,
                    title: "SIGNING DAY",
                    statusMessage: statusMessage,
                    onCommit: onCommit,
                    onContinue: onContinue,
                    onClose: onClose
                )
            } else {
                // The closed branch draws its own world: it does not delegate, so it needs the
                // stage the delegated branch inherits from CollegeOffseasonView.
                CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
                    CoachWorldSystemState(
                        .empty(
                            "Signing day is closed. The signing period is not active "
                                + "in this phase."
                        ),
                        palette: palette
                    )
                }
            }
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
