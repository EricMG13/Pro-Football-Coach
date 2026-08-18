import SwiftUI

public struct AwardsHonoursView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: AwardsHonoursReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: AwardsHonoursReadModel, statusMessage: String? = nil,
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
                if model.awards.isEmpty {
                    CoachWorldSystemState(
                        .empty("No archived honours recorded."),
                        palette: palette
                    )
                } else {
                    ForEach(model.awards) { award in awardRow(award) }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : AwardsMetric.column,
                   alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("Awarded to date", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(
                model.awards.count == 1 ? "1 honour" : "\(model.awards.count) honours",
                palette: palette
            )
        }
    }

    /// One honour: what it is, who has it, and the season it was won in.
    ///
    /// The reference sets a mark at the head of each row. `04` section 6.6 holds `star` and
    /// `checkmark.seal` in the status class, and an award is not a status -- so the row leads with
    /// the award's own name instead, which is what distinguishes one from another anyway.
    private func awardRow(_ award: AwardsHonoursReadModel.Award) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                FloodlitLabel3(award.title, palette: palette)
                Text(award.winner.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: CoachWorldTokens.Gap.hair) {
                Text(award.tier)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
                    .lineLimit(1)
                Text(award.seasonLabel)
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill))
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(1)
            }
            .frame(width: AwardsMetric.seasonColumn, alignment: .trailing)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(CoachWorldCutCorner.row.fill(palette.work.color.opacity(AwardsMetric.rowFill)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(award.title): \(award.winner), \(award.tier), \(award.seasonLabel)"
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Honours already awarded. Nothing here is a nomination.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Back to the league", action: onClose)
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

private enum AwardsMetric {
    /// The handoff's 430pt honours column.
    static let column: CGFloat = 430
    static let seasonColumn: CGFloat = 96
    static let rowFill = 0.32
}
