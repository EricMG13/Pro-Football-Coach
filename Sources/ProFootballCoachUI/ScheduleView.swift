import SwiftUI

public struct ScheduleView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: ScheduleReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: ScheduleReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
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
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.games.isEmpty {
                    CoachWorldSystemState(
                        .empty(
                            "No \(model.tier.lowercased()) games. The schedule is empty "
                                + "for this season."
                        ),
                        palette: palette
                    )
                } else if dynamicTypeSize.isAccessibilitySize {
                    // One column at AX sizes: two 32pt fixtures side by side cannot hold a team
                    // name at that type size without truncating the thing the row is about.
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                        ForEach(model.games) { game in gameRow(game) }
                    }
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: CoachWorldTokens.Gap.xl),
                            GridItem(.flexible(), spacing: CoachWorldTokens.Gap.xl),
                        ],
                        alignment: .leading,
                        spacing: CoachWorldTokens.Gap.tight
                    ) {
                        ForEach(model.games) { game in gameRow(game) }
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(
                "\(model.seasonLabel) \u{00B7} \(gameCountLabel)", palette: palette
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(playedLabel, palette: palette)
        }
    }

    private var gameCountLabel: String {
        model.games.count == 1 ? "one game" : "\(model.games.count) games"
    }

    private var playedLabel: String {
        let played = model.games.filter { $0.score != nil }.count
        let remaining = model.games.count - played
        if remaining == 0 { return "all played" }
        return played == 0
            ? "none played yet"
            : "\(played) played \u{00B7} \(remaining) to play"
    }

    /// One fixture: the week, who is playing whom, and what happened.
    ///
    /// The reference names one opponent and a venue chip. That needs to know which side is the
    /// coach's, and `ScheduleReadModel` does not carry it: `isControlled` says only that the
    /// programme is *in* this fixture, not which end of it. So both teams are named, in the
    /// away-at-home order the sport states them, and the coach's own fixture takes the selected
    /// treatment. Deriving a venue from `isControlled` would have labelled every home game away.
    private func gameRow(_ game: ScheduleReadModel.GameRow) -> some View {
        let homeID = UUID(uuidString: game.home.stableID)
        return Button {
            if let homeID { onSelectTeam(homeID) }
        } label: {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(game.week.uppercased())
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                    .foregroundStyle(
                        game.score == nil ? palette.actionPrimary.color : palette.contentQuiet.color
                    )
                    .lineLimit(1)
                    .frame(width: ScheduleMetric.weekColumn, alignment: .leading)
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
                Group {
                    if game.score == nil {
                        Text(game.score ?? game.stage)
                            .font(CoachWorldTokens.TypeRole.caption)
                    } else {
                        Text(game.score ?? game.stage)
                            .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    }
                }
                .foregroundStyle(
                    game.score == nil ? palette.contentQuiet.color : palette.contentPrimary.color
                )
                .lineLimit(game.score == nil ? 2 : 1)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: ScheduleMetric.resultColumn, alignment: .trailing)
            }
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .frame(minHeight: ScheduleMetric.rowHeight)
            .background(
                CoachWorldCutCorner.row.fill(
                    palette.work.color.opacity(
                        game.isControlled ? ScheduleMetric.ownFill : ScheduleMetric.rowFill
                    )
                )
            )
            .overlay {
                if game.isControlled {
                    CoachWorldCutCorner.row.stroke(
                        palette.actionPrimary.color, lineWidth: CoachWorldTokens.Shape.hairline
                    )
                }
            }
            .contentShape(CoachWorldCutCorner.row)
        }
        .buttonStyle(.plain)
        .disabled(homeID == nil)
        .accessibilityLabel(
            "\(game.week), \(game.away.name) at \(game.home.name), "
                + (game.score.map { "final \($0)" } ?? "not played")
                + (game.isControlled ? ". Your fixture." : "")
        )
    }

    private var footer: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.sm) {
                    Text("Home and away are as scheduled. Nothing here is a prediction.")
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    FloodlitCommittingAction("Advance week", action: onContinue)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
                    Text("Home and away are as scheduled. Nothing here is a prediction.")
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitCommittingAction("Advance week", action: onContinue)
                }
            }
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum ScheduleMetric {
    static let weekColumn: CGFloat = 34
    static let resultColumn: CGFloat = 104
    static let rowHeight: CGFloat = 46
    static let rowFill = 0.32
    static let ownFill = 0.5
}
