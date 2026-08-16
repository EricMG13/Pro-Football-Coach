import SwiftUI

/// Read-only beta product commitments. Presentation preferences remain system-owned until their
/// persisted contract is introduced; this surface never implies a setting was changed.
public struct SettingsAccessibilityView: View {
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                Text("SETTINGS & ACCESSIBILITY")
                    .font(CoachWorldTokens.TypeRole.display.weight(.black))
                Text("BETA PRODUCT CONTRACT")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                Text("English-only beta · landscape play · silent product")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Text("No audio, haptics, account, network, analytics, advertising, or in-app purchase channels are used.")
                    .font(CoachWorldTokens.TypeRole.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("VoiceOver, Dynamic Type, Bold Text, Increase Contrast, Reduce Transparency, Differentiate Without Color, and Reduce Motion are supported by each shipped surface.")
                    .font(CoachWorldTokens.TypeRole.body)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Done", action: onClose)
                    .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            .padding(CoachWorldTokens.Space.xl)
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
    }
}
