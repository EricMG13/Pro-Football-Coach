import SwiftUI

public struct StatisticsLeadersView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: StatisticsLeadersReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: StatisticsLeadersReadModel, statusMessage: String? = nil,
                onClose: @escaping () -> Void) {
        self.model = model; self.statusMessage = statusMessage; self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.rows.isEmpty {
                    CoachWorldSystemState(
                        .empty("No player statistics recorded."),
                        palette: palette
                    )
                } else if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                        ForEach(model.rows) { row in leaderRow(row) }
                    }
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: CoachWorldTokens.Gap.xl),
                            GridItem(.flexible(), spacing: CoachWorldTokens.Gap.xl),
                        ],
                        alignment: .leading,
                        spacing: CoachWorldTokens.Gap.xxs
                    ) {
                        ForEach(model.rows) { row in leaderRow(row) }
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("Statistics and leaders", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(
                "\(model.seasonLabel) \u{00B7} \(model.weekLabel)", palette: palette
            )
        }
    }

    /// One leader: what the category is, who leads it, for whom, and by how much.
    private func leaderRow(_ row: StatisticsLeadersReadModel.Row) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                FloodlitLabel3(row.category, palette: palette)
                Text(row.player.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(row.team.name)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .lineLimit(1)
                .frame(width: StatisticsMetric.teamColumn, alignment: .leading)
            Text("\(row.value)")
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.title, weight: .semibold))
                .frame(width: StatisticsMetric.valueColumn, alignment: .trailing)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(CoachWorldCutCorner.row.fill(palette.work.color.opacity(StatisticsMetric.rowFill)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(row.category): \(row.player.name), \(row.team.name), \(row.value)"
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Season totals to date. Nobody is projected forward.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Back to the league", action: onClose)
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum StatisticsMetric {
    static let teamColumn: CGFloat = 84
    static let valueColumn: CGFloat = 58
    static let rowFill = 0.32
}
