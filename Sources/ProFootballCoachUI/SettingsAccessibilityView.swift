import SwiftUI
import FootballSimCore

/// Beta product commitments, plus the one setting that persists to the current save: the call-in
/// rate (`02` section 3.1). Device- and OS-owned presentation preferences (Dynamic Type, VoiceOver,
/// Reduce Motion) remain system-owned -- this surface still never implies one of *those* changed.
/// `callInsPerGame`/`onSetCallInsPerGame` are nil when there is no career to hold the preference
/// (reached from the title screen before any save is loaded); the control is omitted then, since
/// there is nothing yet to read or write.
public struct SettingsAccessibilityView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let onClose: () -> Void
    public let callInsPerGame: Int?
    public let onSetCallInsPerGame: ((Int) -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        onClose: @escaping () -> Void,
        callInsPerGame: Int? = nil,
        onSetCallInsPerGame: ((Int) -> Void)? = nil
    ) {
        self.onClose = onClose
        self.callInsPerGame = callInsPerGame
        self.onSetCallInsPerGame = onSetCallInsPerGame
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    Text("SETTINGS & ACCESSIBILITY")
                        .font(CoachWorldTokens.TypeRole.display.weight(.black))
                    Text("BETA PRODUCT CONTRACT")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.contentSecondary.color)
                    Text("English-only beta · landscape play · silent product")
                        .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                    Text("No audio, haptics, account, network, analytics, advertising, or in-app purchase channels are used.")
                        .font(CoachWorldTokens.TypeRole.body)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The shipped surfaces provide VoiceOver labels, Dynamic Type reflow, visible selection, and reduced-motion-safe presentation. System-owned settings remain outside this beta surface.")
                        .font(CoachWorldTokens.TypeRole.body)
                        .fixedSize(horizontal: false, vertical: true)
                    if let callInsPerGame, let onSetCallInsPerGame {
                        callInRateControl(callInsPerGame, onSetCallInsPerGame)
                    }
                    Button("Close", action: onClose)
                        .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                }
                .padding(CoachWorldTokens.Space.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }

    private func callInRateControl(
        _ value: Int, _ onSet: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("PACING")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Stepper(
                "Call-ins per game: \(value)",
                value: Binding(get: { value }, set: onSet),
                in: SharedRules.callInsPerGameRange
            )
            .font(CoachWorldTokens.TypeRole.body)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            Text("How often the coordinator hands you a decision, from \(SharedRules.callInsPerGameRange.lowerBound) to \(SharedRules.callInsPerGameRange.upperBound) a game.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
