import SwiftUI

/// Shared rankings/playoff picture surface. Ranking and bracket data are read from the same
/// competition snapshot so the two views cannot disagree about the field.
public struct CompetitionOverviewView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: CompetitionOverviewReadModel
    public let focus: CoachWorldScreenID
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: CompetitionOverviewReadModel,
        focus: CoachWorldScreenID,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
        self.focus = focus
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
        self.onSelectTeam = onSelectTeam
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
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                focusedColumns
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(
                "\(model.tier) \u{00B7} \(model.seasonLabel)", palette: palette
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(focusLabel, palette: palette, tint: palette.actionPrimary.color)
        }
    }

    /// Three registry entries share this composition. What differs is which column the route is
    /// about, so the label says which -- not a different screen with the same data in it.
    private var focusLabel: String {
        switch focus {
        case .rankingsPlayoffPicture: "Rankings"
        case .bracketPostseason: "Postseason bracket"
        default: "Rankings and bracket"
        }
    }

    @ViewBuilder
    private var focusedColumns: some View {
        switch focus {
        case .rankingsPlayoffPicture:
            rankingColumn
        case .bracketPostseason:
            bracketColumn
        default:
            if dynamicTypeSize.isAccessibilitySize {
                rankingColumn
                bracketColumn
            } else {
                HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                    rankingColumn
                        .frame(width: CompetitionMetric.rankingColumn)
                    bracketColumn
                }
            }
        }
    }

    /// The ranked field, in the order the competition records it.
    private var rankingColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Ranked", palette: palette)
            if model.rankings.isEmpty {
                CoachWorldSystemState(
                    .empty("No ranking is recorded for this competition yet."),
                    palette: palette
                )
            } else {
                ForEach(model.rankings) { row in rankingRow(row) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rankingRow(_ row: CompetitionOverviewReadModel.RankingRow) -> some View {
        Button {
            if let id = UUID(uuidString: row.team.stableID) { onSelectTeam(id) }
        } label: {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text("\(row.rank)")
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.row, weight: .semibold)
                    .foregroundStyle(
                        row.isControlled ? palette.actionPrimary.color : palette.contentQuiet.color
                    )
                    .frame(width: CompetitionMetric.rankColumn, alignment: .leading)
                Text(row.team.name.uppercased())
                    .coachWorldDisplay(
                        CoachWorldTokens.DisplaySize.actionSmall,
                        weight: row.isControlled ? .heavy : .bold
                    )
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(row.record)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentSecondary.color)
                    .frame(width: CompetitionMetric.recordColumn, alignment: .trailing)
            }
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .frame(minHeight: CompetitionMetric.rowHeight)
            .background(
                CoachWorldCutCorner.row.fill(
                    palette.work.color.opacity(
                        row.isControlled ? CompetitionMetric.ownFill : CompetitionMetric.rowFill
                    )
                )
            )
            .overlay {
                if row.isControlled {
                    CoachWorldCutCorner.row.stroke(
                        palette.actionPrimary.color, lineWidth: CoachWorldTokens.Shape.hairline
                    )
                }
            }
            .contentShape(CoachWorldCutCorner.row)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Number \(row.rank), \(row.team.name), \(row.record)"
                + (row.isControlled ? ". Your programme." : "")
        )
    }

    /// The postseason, grouped by the stage each game belongs to.
    ///
    /// The reference draws a bracket as connected lines. This build records a flat list of games
    /// with a stage name and no parent-child link between rounds, so the stages are drawn as
    /// groups. Lines that imply who advances into whom would be a claim the model does not make.
    private var bracketColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.sm) {
            if model.bracket.isEmpty {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                    FloodlitLabel3("Postseason", palette: palette)
                    CoachWorldSystemState(
                        .empty("The postseason has not been scheduled yet."),
                        palette: palette
                    )
                }
            } else {
                ForEach(stages, id: \.self) { stage in
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                        FloodlitLabel3(stage, palette: palette, tint: palette.stateInfo.color)
                        ForEach(model.bracket.filter { $0.stage == stage }) { game in
                            bracketRow(game)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stages: [String] {
        var seen = Set<String>()
        return model.bracket.compactMap { seen.insert($0.stage).inserted ? $0.stage : nil }
    }

    private func bracketRow(_ game: CompetitionOverviewReadModel.BracketGame) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            Text(game.week.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                .foregroundStyle(palette.contentQuiet.color)
                .lineLimit(1)
                .frame(width: CompetitionMetric.weekColumn, alignment: .leading)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text(game.away.name.uppercased())
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                    .lineLimit(1)
                Text("at \(game.home.name)".uppercased())
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                    .foregroundStyle(palette.contentQuiet.color)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(game.score ?? "to play")
                .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                .foregroundStyle(
                    game.score == nil ? palette.contentQuiet.color : palette.contentPrimary.color
                )
                .lineLimit(1)
                .frame(width: CompetitionMetric.scoreColumn, alignment: .trailing)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: CompetitionMetric.bracketRowHeight)
        .background(CoachWorldCutCorner.row.fill(palette.work.color.opacity(CompetitionMetric.rowFill)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(game.stage), \(game.week), \(game.away.name) at \(game.home.name), "
                + (game.score.map { "final \($0)" } ?? "not played")
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("The field as it stands. Nobody is projected into a round they have not reached.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Advance week", action: onContinue)
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum CompetitionMetric {
    static let rankingColumn: CGFloat = 330
    static let rankColumn: CGFloat = 24
    static let recordColumn: CGFloat = 56
    static let weekColumn: CGFloat = 34
    static let scoreColumn: CGFloat = 62
    static let rowHeight: CGFloat = 29
    static let bracketRowHeight: CGFloat = 38
    static let rowFill = 0.32
    static let ownFill = 0.5
}
