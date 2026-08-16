import SwiftUI

public struct AwardsHonoursView: View {
    public let model: AwardsHonoursReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: AwardsHonoursReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model; self.statusMessage = statusMessage; self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: CoachWorldTokens.Space.sm) {
                Button("League", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                Text("Awards & honours").font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Spacer()
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .background(palette.raised.color)
            if let statusMessage { Text(statusMessage).frame(maxWidth: .infinity, alignment: .leading) }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    if model.awards.isEmpty { Text("No archived honours recorded.") }
                    ForEach(model.awards) { award in
                        HStack {
                            VStack(alignment: .leading, spacing: .zero) {
                                Text(award.title).fontWeight(.bold)
                                Text(award.winner + " · " + award.tier)
                                    .font(CoachWorldTokens.TypeRole.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(award.seasonLabel).font(CoachWorldTokens.TypeRole.caption)
                            Text(String(award.value)).monospacedDigit()
                        }
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(award.title), \(award.winner), \(award.tier), \(award.seasonLabel), value \(award.value)")
                    }
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }
}
