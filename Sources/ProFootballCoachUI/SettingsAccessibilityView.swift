import SwiftUI

/// Read-only beta product commitments. Presentation preferences remain system-owned until their
/// persisted contract is introduced; this surface never implies a setting was changed.
public struct SettingsAccessibilityView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
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
}
