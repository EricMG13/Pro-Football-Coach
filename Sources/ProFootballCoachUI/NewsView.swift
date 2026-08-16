import SwiftUI

public struct NewsView: View {
    public let model: NewsReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: NewsReadModel, statusMessage: String? = nil, onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
    }

    public var body: some View {
        let palette = colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                header(palette: palette)
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.items.isEmpty {
                    ContentUnavailableView(
                        "No news recorded",
                        systemImage: "list.number",
                        description: Text("Typed world events will appear here when they become newsworthy.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    ForEach(model.items) { item in
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                            Text(item.headline)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(item.occurred)
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentSecondary.color)
                        }
                        .padding(CoachWorldTokens.Space.sm)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                        .background(palette.raised.color.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.headline), \(item.occurred)")
                    }
                }
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .accessibilitySortPriority(100)
    }

    @ViewBuilder
    private func header(palette: CoachWorldTokens.Palette) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                titleBlock(palette: palette)
                closeButton
            }
        } else {
            HStack(alignment: .top) {
                titleBlock(palette: palette)
                Spacer(minLength: CoachWorldTokens.Space.sm)
                closeButton
            }
        }
    }

    private func titleBlock(palette: CoachWorldTokens.Palette) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("NEWS")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text("World news")
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text(model.weekLabel)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }
}
