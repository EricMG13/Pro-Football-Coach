import SwiftUI

public struct StatisticsLeadersView: View {
    public let model: StatisticsLeadersReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    public init(model: StatisticsLeadersReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model; self.statusMessage = statusMessage; self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: CoachWorldTokens.Space.sm) {
                Button("League", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                VStack(alignment: .leading, spacing: .zero) {
                    Text("Statistics & leaders").font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    Text(model.seasonLabel + " · " + model.weekLabel)
                        .font(CoachWorldTokens.TypeRole.caption)
                }
                Spacer()
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .background(palette.raised.color)
            if let statusMessage { Text(statusMessage).frame(maxWidth: .infinity, alignment: .leading) }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    if model.rows.isEmpty { Text("No player statistics recorded.") }
                    ForEach(model.rows) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: .zero) {
                                Text(row.category).font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                Text(row.player.name)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.team.name).font(CoachWorldTokens.TypeRole.caption)
                            Text(String(row.value)).monospacedDigit().fontWeight(.bold)
                        }
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(row.category), \(row.player.name), \(row.value), \(row.team.name)")
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
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }
}
