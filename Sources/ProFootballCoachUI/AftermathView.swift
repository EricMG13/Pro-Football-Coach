import SwiftUI

public struct AftermathView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: AftermathReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onOpenBoxScore: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: AftermathReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onOpenBoxScore: (() -> Void)? = nil
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onOpenBoxScore = onOpenBoxScore
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
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: 15) }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    finalScore
                    gradeTable
                    planPanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
                            finalScore
                            gradeTable
                        }
                        planPanel
                            .frame(width: AftermathMetric.panelWidth)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { payoffStrip }
    }

    /// The result, read the way a result is read: the side that won first and largest.
    ///
    /// The reference sets the winner at 34/54 and the loser at 25/40. A draw has no winner to
    /// lead with, so both sides take the winner's weight rather than one being arbitrarily demoted.
    private var finalScore: some View {
        let sides = model.home.score >= model.away.score
            ? [model.home, model.away]
            : [model.away, model.home]
        let isDraw = model.home.score == model.away.score
        return FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                FloodlitLabel3(
                    "Final \u{00B7} \(model.venue.name) \u{00B7} \(model.resultLabel)",
                    palette: palette
                )
                ForEach(Array(sides.enumerated()), id: \.offset) { index, side in
                    if index == 0 {
                        scoreLine(side, isLead: true)
                            .accessibilityIdentifier("weekly-command-dominant")
                    } else {
                        scoreLine(side, isLead: isDraw)
                    }
                }
            }
        }
    }

    private func scoreLine(_ side: MatchDayReadModel.TeamScore, isLead: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(side.team.name.uppercased())
                .font(
                    CoachWorldTokens.display(
                        isLead
                            ? CoachWorldTokens.DisplaySize.figure
                            : CoachWorldTokens.DisplaySize.screen,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    isLead ? palette.contentPrimary.color : palette.contentSecondary.color
                )
                .lineLimit(1)
                .minimumScaleFactor(AftermathMetric.nameScaleFloor)
            Text("\(side.score)")
                .font(
                    CoachWorldTokens.figure(
                        isLead
                            ? CoachWorldTokens.DisplaySize.score
                            : CoachWorldTokens.DisplaySize.scoreLive,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    isLead ? palette.contentPrimary.color : palette.contentSecondary.color
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(side.team.name), \(side.score)")
    }

    /// The graded snaps, one row each: position, name, the grade as a bar, the grade as a figure.
    ///
    /// The reference carries a delta column against the player's season grade. Nothing in
    /// `AftermathReadModel.Grade` records a prior grade, so the column is absent rather than
    /// filled with a difference from a number that does not exist.
    @ViewBuilder
    private var gradeTable: some View {
        if !model.grades.isEmpty {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                    FloodlitLabel3("Grades", palette: palette)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitLabel3(
                        model.grades.count == 1 ? "1 player graded"
                                                : "\(model.grades.count) players graded",
                        palette: palette
                    )
                }
                ForEach(model.grades) { grade in
                    gradeRow(grade)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func gradeRow(_ grade: AftermathReadModel.Grade) -> some View {
        let tint = CoachWorldTokens.Heat.color(for: grade.rating, palette: palette)
        return HStack(spacing: CoachWorldTokens.Gap.md) {
            Text(grade.position.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                .tracking(
                    CoachWorldTokens.DisplaySize.tracking(
                        AftermathMetric.positionTracking, at: CoachWorldTokens.DisplaySize.pill
                    )
                )
                .foregroundStyle(palette.stateInfo.color)
                .lineLimit(1)
                .frame(width: AftermathMetric.positionColumn, alignment: .leading)
            Text(grade.player.name)
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                .lineLimit(1)
                .frame(width: AftermathMetric.nameColumn, alignment: .leading)
            FloodlitShareBar(proportion: proportion(of: grade.rating), tint: tint, palette: palette)
            Text("\(grade.rating)")
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.row, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: AftermathMetric.gradeColumn, alignment: .trailing)
        }
        .frame(minHeight: AftermathMetric.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(grade.position) \(grade.player.name), graded \(grade.rating). \(grade.evidence)"
        )
    }

    /// Where a grade sits on the rating scale, so the bar is a position on 40-99 rather than a
    /// percentage of 99 -- a 45 is a bad grade, not a bar that is nearly half full.
    private func proportion(of rating: Int) -> Double {
        let floor = CoachWorldTokens.Heat.scaleFloor
        let ceiling = CoachWorldTokens.Heat.scaleCeiling
        let clamped = min(max(rating, floor), ceiling)
        return Double(clamped - floor) / Double(ceiling - floor)
    }

    /// The reference's "What the plan did": what the coach's own decisions turned into.
    private var planPanel: some View {
        FloodlitCard(palette: palette, depth: .glass) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("What the plan did", palette: palette)
                panelGroup("What the game turned on", model.evidence)
                panelGroup(
                    "Called in",
                    model.callIns.isEmpty ? ["Nothing was called in."] : model.callIns
                )
                panelGroup(
                    "Injuries",
                    model.injuries.isEmpty ? ["Nobody came off hurt."] : model.injuries
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func panelGroup(_ title: String, _ lines: [String]) -> some View {
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                FloodlitLabel3(title, palette: palette)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// The payoff strip: what the result did to the season, then the way out of the screen.
    private var payoffStrip: some View {
        // The reference sets a trend mark at the head of this strip. `04` section 6.6 does not hold
        // one, and a symbol outside the register is a finding rather than a licence -- so the
        // sentence carries the meaning alone, which is what it was doing anyway.
        HStack(spacing: CoachWorldTokens.Gap.xl) {
            Text(model.headline)
                .font(CoachWorldTokens.TypeRole.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            if let onOpenBoxScore {
                Button("Box score", action: onOpenBoxScore)
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .foregroundStyle(palette.contentQuiet.color)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            FloodlitCommittingAction("Next week", action: onContinue)
        }
        .padding(.vertical, CoachWorldTokens.Pad.alert.v)
        .padding(.horizontal, CoachWorldTokens.Pad.alert.h)
        .frame(maxWidth: .infinity)
        .background(CoachWorldCutCorner.row.fill(CoachWorldTokens.Floodlit.glassFlatDeep.color))
        .overlay {
            CoachWorldCutCorner.row.stroke(
                Color.white.opacity(CoachWorldTokens.Glass.line),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

private enum AftermathMetric {
    /// The handoff's 223pt panel.
    static let panelWidth: CGFloat = 223
    static let positionColumn: CGFloat = 46
    static let nameColumn: CGFloat = 118
    static let gradeColumn: CGFloat = 34
    static let rowHeight: CGFloat = 20
    static let positionTracking: CGFloat = 0.08
    static let nameScaleFloor: CGFloat = 0.7
}
