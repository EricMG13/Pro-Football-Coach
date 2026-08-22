import SwiftUI

public struct StandingsView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: StandingsReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: StandingsReadModel,
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
            LazyVStack(alignment: .leading, spacing: .zero) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !dynamicTypeSize.isAccessibilitySize { columnHeads }
                if model.rows.isEmpty {
                    CoachWorldSystemState(
                        .empty("No standings are recorded for this tier."),
                        palette: palette
                    )
                } else {
                    ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                        standingsRow(index: index, row: row)
                    }
                }
            }
            // League & Media, `04` section 2: "a standing resettles in place between weeks" -- rows
            // are keyed by id, not index, so a rank change interpolates rather than cross-fading
            // unrelated rows into each other's places.
            .coachWorldAnimation(CoachWorldTokens.Motion.world, value: model.rows)
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("\(model.tier) standings", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(
                "\(model.seasonLabel) \u{00B7} \(model.weekLabel)", palette: palette
            )
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .padding(.bottom, CoachWorldTokens.Gap.xs)
    }

    private var columnHeads: some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("#", palette: palette)
                .frame(width: StandingsMetric.rankColumn, alignment: .leading)
            FloodlitLabel3("Team", palette: palette)
                .frame(maxWidth: .infinity, alignment: .leading)
            FloodlitLabel3("Rec", palette: palette)
                .frame(width: StandingsMetric.recordColumn, alignment: .leading)
            FloodlitLabel3("Conf", palette: palette)
                .frame(width: StandingsMetric.conferenceColumn, alignment: .leading)
            FloodlitLabel3("Points", palette: palette)
                .frame(width: StandingsMetric.pointsColumn, alignment: .trailing)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: StandingsMetric.headHeight)
        .accessibilityHidden(true)
    }

    /// The coach's own programme is the one row a coach looks for, so it takes the selected
    /// treatment -- a gold hairline, never a fill, which `04` section 6.5 reserves for the
    /// committing action.
    private func standingsRow(index: Int, row: StandingsReadModel.Row) -> some View {
        let teamID = UUID(uuidString: row.team.stableID)
        return Button {
            if let teamID { onSelectTeam(teamID) }
        } label: {
            rowBody(index: index, row: row)
        }
        .buttonStyle(.plain)
        .disabled(teamID == nil)
        .accessibilityLabel(
            "\(index + 1). \(row.team.name), \(recordLabel(row)), "
                + "conference \(row.conferenceRecord), "
                + "\(row.pointsFor) points for, \(row.pointsAgainst) against"
                + (row.isControlled ? ". Your programme." : "")
        )
    }

    /// At accessibility sizes the five columns stack into a block. A table that keeps its columns
    /// at AX5 truncates the team name, which is the one field the row exists to state
    /// (`04` section 7.1).
    @ViewBuilder
    private func rowBody(index: Int, row: StandingsReadModel.Row) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                HStack(spacing: CoachWorldTokens.Gap.xs) {
                    CoachWorldTeamLogo(
                        team: row.team,
                        size: .compact,
                        surface: palette.work,
                        palette: palette
                    )
                    Text("\(index + 1). \(row.team.name)")
                        .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(
                    "\(recordLabel(row)) \u{00B7} conference \(row.conferenceRecord)"
                )
                .font(CoachWorldTokens.TypeRole.body)
                .fixedSize(horizontal: false, vertical: true)
                Text("\(row.pointsFor) for, \(row.pointsAgainst) against")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(CoachWorldTokens.Pad.row.h)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                CoachWorldCutCorner.row.fill(
                    palette.work.color.opacity(
                        row.isControlled ? StandingsMetric.ownFill : StandingsMetric.rowFill
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
        } else {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text("\(index + 1)")
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.row, weight: .semibold)
                    .foregroundStyle(
                        row.isControlled ? palette.actionPrimary.color : palette.contentQuiet.color
                    )
                    .frame(width: StandingsMetric.rankColumn, alignment: .leading)
                HStack(spacing: CoachWorldTokens.Gap.xs) {
                    CoachWorldTeamLogo(
                        team: row.team,
                        size: .compact,
                        surface: palette.work,
                        palette: palette
                    )
                    Text(row.team.name.uppercased())
                        .coachWorldDisplay(
                            CoachWorldTokens.DisplaySize.row,
                            weight: row.isControlled ? .heavy : .bold
                        )
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(recordLabel(row))
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .frame(width: StandingsMetric.recordColumn, alignment: .leading)
                Text(row.conferenceRecord)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentSecondary.color)
                    .frame(width: StandingsMetric.conferenceColumn, alignment: .leading)
                Text("\(row.pointsFor)\u{2013}\(row.pointsAgainst)")
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentSecondary.color)
                    .frame(width: StandingsMetric.pointsColumn, alignment: .trailing)
            }
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .frame(minHeight: StandingsMetric.rowHeight)
            .background(
                CoachWorldCutCorner.row.fill(
                    palette.work.color.opacity(
                        row.isControlled ? StandingsMetric.ownFill : StandingsMetric.rowFill
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
    }

    private func recordLabel(_ row: StandingsReadModel.Row) -> String {
        row.ties > 0
            ? "\(row.wins)-\(row.losses)-\(row.ties)"
            : "\(row.wins)-\(row.losses)"
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(note)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Advance week", action: onContinue)
        }
        .floodlitFooterStrip(palette: palette)
    }

    /// What the table is and is not. It is the recorded season to date, not a projection of where
    /// anyone finishes.
    private var note: String {
        let count = model.rows.count
        let teams = count == 1 ? "one programme" : "\(count) programmes"
        return "\(teams), as the season has actually been played. Nothing here is a forecast."
    }
}

private enum StandingsMetric {
    static let rankColumn: CGFloat = 22
    static let recordColumn: CGFloat = 56
    static let conferenceColumn: CGFloat = 56
    static let pointsColumn: CGFloat = 84
    static let rowHeight: CGFloat = 29
    static let headHeight: CGFloat = 17
    static let rowFill = 0.32
    static let ownFill = 0.5
}
