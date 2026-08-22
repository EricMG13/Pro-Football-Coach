import SwiftUI

/// Detailed game/box-score family backed by the immutable post-game evidence projection.
public struct GameDetailBoxScoreView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: AftermathReadModel
    public let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: AftermathReadModel, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(
            palette: palette,
            register: .broadcast,
            chrome: chrome,
            onNavigate: onNavigateChrome
        ) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                if dynamicTypeSize.isAccessibilitySize {
                    scoreLines
                    evidencePanel
                    whoDidIt
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
                            scoreLines
                            evidencePanel
                        }
                        whoDidIt
                            .frame(width: BoxScoreMetric.columnWidth)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { relatedStrip }
    }

    /// The two score lines, in the reference's geometry: the team at 132, the total as a figure.
    ///
    /// The reference sets four quarter columns between them. `AftermathReadModel` records a final
    /// score and nothing per quarter, so the columns are absent. Four cells reading the final score
    /// divided four ways would be a scoring summary the game never played.
    private var scoreLines: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                FloodlitLabel3(
                    "Final \u{00B7} \(model.venue.name) \u{00B7} \(model.resultLabel)",
                    palette: palette
                )
                .accessibilityIdentifier("weekly-command-screen-47")
                scoreLine(model.away)
                    .accessibilityIdentifier("weekly-command-dominant")
                scoreLine(model.home)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func scoreLine(_ side: MatchDayReadModel.TeamScore) -> some View {
        let won = side.score > opposing(side).score
        return HStack(spacing: CoachWorldTokens.Gap.md) {
            Text(side.team.name.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                .foregroundStyle(
                    won ? palette.contentPrimary.color : palette.contentSecondary.color
                )
                .lineLimit(1)
                .frame(width: BoxScoreMetric.teamColumn, alignment: .leading)
            if let subline = side.subline {
                Text(subline)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentQuiet.color)
                    .lineLimit(1)
            }
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Text("\(side.score)")
                .coachWorldFigure(CoachWorldTokens.DisplaySize.screen, weight: .semibold)
                .foregroundStyle(
                    won ? palette.contentPrimary.color : palette.contentSecondary.color
                )
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: BoxScoreMetric.scoreRowHeight)
        .background(CoachWorldCutCorner.row.fill(palette.work.color.opacity(BoxScoreMetric.rowFill)))
        .overlay {
            CoachWorldCutCorner.row.stroke(
                Color.white.opacity(CoachWorldTokens.Glass.line),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(side.team.name), \(side.score)")
    }

    private func opposing(_ side: MatchDayReadModel.TeamScore) -> MatchDayReadModel.TeamScore {
        side.team.stableID == model.home.team.stableID ? model.away : model.home
    }

    /// The reference's "Who did it": position, name, and the line that says what they did.
    ///
    /// The reference's stat line is a figure string -- 18/26, 241 yards. This build records a grade
    /// and the evidence sentence behind it, so the evidence is what the column carries. It is the
    /// same claim the reference makes, stated in the terms the simulation actually holds.
    @ViewBuilder
    private var whoDidIt: some View {
        if !model.grades.isEmpty {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                FloodlitLabel3("Who did it", palette: palette)
                ForEach(model.grades) { grade in
                    FloodlitRow(palette: palette) {
                        HStack(spacing: CoachWorldTokens.Gap.md) {
                            Text(grade.position.uppercased())
                                .coachWorldDisplay(CoachWorldTokens.DisplaySize.pill, weight: .bold)
                                .tracking(
                                    CoachWorldTokens.DisplaySize.tracking(
                                        BoxScoreMetric.positionTracking,
                                        at: CoachWorldTokens.DisplaySize.pill
                                    )
                                )
                                .foregroundStyle(palette.stateInfo.color)
                                .lineLimit(1)
                                .frame(width: BoxScoreMetric.positionColumn, alignment: .leading)
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                                Text(grade.player.name.uppercased())
                                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                                    .lineLimit(1)
                                Text(grade.evidence)
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: CoachWorldTokens.Gap.xs)
                            Text("\(grade.rating)")
                                .coachWorldFigure(CoachWorldTokens.DisplaySize.row, weight: .semibold)
                                .foregroundStyle(
                                    CoachWorldTokens.Heat.color(for: grade.rating, palette: palette)
                                )
                        }
                    }
                    .accessibilityLabel(
                        "\(grade.position) \(grade.player.name), graded \(grade.rating). "
                            + grade.evidence
                    )
                }
            }
        }
    }

    /// The reference puts opposed team totals here. This build records the game as evidence
    /// sentences rather than as a totals table, so the sentences are what the column holds; an
    /// opposed bar needs two figures, and there are none to oppose.
    private var evidencePanel: some View {
        FloodlitCard(palette: palette, depth: .glass) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                evidenceGroup(
                    "How the game went",
                    model.evidence,
                    empty: "No detailed game evidence recorded."
                )
                evidenceGroup(
                    "Called in",
                    model.callIns,
                    empty: "No controlled call-ins recorded."
                )
                evidenceGroup(
                    "Injuries",
                    model.injuries,
                    empty: "No injury evidence recorded."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func evidenceGroup(_ title: String, _ rows: [String], empty: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            FloodlitLabel3(title, palette: palette)
            ForEach(Array((rows.isEmpty ? [empty] : rows).enumerated()), id: \.offset) { _, row in
                Text(row)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(
                        rows.isEmpty ? palette.contentQuiet.color : palette.contentSecondary.color
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The reference's related strip: what the game meant, then the ways out of it.
    private var relatedStrip: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(model.headline)
                .font(CoachWorldTokens.TypeRole.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Back to the aftermath", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .padding(.vertical, CoachWorldTokens.Pad.alert.v)
        .padding(.horizontal, CoachWorldTokens.Pad.alert.h)
        .frame(maxWidth: .infinity)
        .background(
            CoachWorldCutCorner.row.fill(CoachWorldTokens.Floodlit.glassFlatDeep.color)
        )
        .overlay {
            CoachWorldCutCorner.row.stroke(
                Color.white.opacity(CoachWorldTokens.Glass.line),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

private enum BoxScoreMetric {
    /// The handoff's 283pt "who did it" column.
    static let columnWidth: CGFloat = 283
    static let teamColumn: CGFloat = 132
    static let positionColumn: CGFloat = 34
    static let scoreRowHeight: CGFloat = 34
    static let positionTracking: CGFloat = 0.08
    static let rowFill = 0.5
}
