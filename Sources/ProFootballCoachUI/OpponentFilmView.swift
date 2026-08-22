import SwiftUI

public struct OpponentFilmView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: OpponentFilmReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: OpponentFilmReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
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
                if let reason = model.unavailableReason {
                    CoachWorldSystemState(
                        .empty("Opponent film unavailable. " + reason),
                        palette: palette
                    )
                    .accessibilityIdentifier("weekly-command-dominant")
                } else if dynamicTypeSize.isAccessibilitySize {
                    tendencies
                    sourcePanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        tendencies
                        sourcePanel
                            .frame(width: FilmMetric.panelWidth)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { commitBar }
    }

    /// The reference's heading: whose film, and how much of it there is.
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(headline, palette: palette)
                .accessibilityIdentifier("weekly-command-screen-10")
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            if !model.isCurrent {
                FloodlitLabel3("Stale", palette: palette, tint: palette.stateWarning.color)
            }
        }
    }

    private var headline: String {
        let opponent = model.opponent?.name ?? "No scheduled opponent"
        let games = model.sourceGameCount
        let held = games == 1 ? "what one game of film holds"
                              : "what \(games) games of film hold"
        return "\(opponent) \u{00B7} \(held)"
    }

    /// The tendency rows, in the reference's geometry: what the situation is, the share as a bar,
    /// the split as a figure, and how much film it rests on.
    ///
    /// The reference draws six rows against a scouting model this build does not have. Two are
    /// drawn, because two are what the read model holds: pass rate and turnover rate. A row for
    /// down-and-distance tendency would be a figure with nothing behind it, and `04` section 4.4
    /// refuses invented evidence more firmly than it dislikes a short table.
    private var tendencies: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                FloodlitLabel3("What the film says", palette: palette)
                    .accessibilityIdentifier("weekly-command-dominant")
                tendencyRow(
                    "Pass rate",
                    proportion: Double(model.passRate) / FilmMetric.percentScale,
                    split: "\(model.passRate)% pass \u{00B7} \(100 - model.passRate)% run"
                )
                tendencyRow(
                    "Turnovers",
                    proportion: Double(model.turnoverRate) / FilmMetric.percentScale,
                    split: "\(model.turnoverRate)% of drives"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tendencyRow(
        _ situation: String,
        proportion: Double,
        split: String
    ) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            Text(situation.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                .lineLimit(1)
                .frame(width: FilmMetric.situationColumn, alignment: .leading)
            FloodlitShareBar(
                proportion: proportion,
                tint: palette.stateInfo.color,
                palette: palette
            )
            Text(split)
                .coachWorldFigure(CoachWorldTokens.DisplaySize.row, weight: .semibold)
                .lineLimit(1)
                .frame(width: FilmMetric.splitColumn, alignment: .trailing)
            Text(filmedLabel)
                .coachWorldFigure(CoachWorldTokens.DisplaySize.pill, weight: .regular)
                .foregroundStyle(palette.contentQuiet.color)
                .lineLimit(1)
                .frame(width: FilmMetric.filmedColumn, alignment: .trailing)
        }
        .frame(minHeight: FilmMetric.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(situation), \(split), from \(filmedLabel)")
    }

    private var filmedLabel: String {
        model.sourceFixtureCount == 1 ? "1 fixture" : "\(model.sourceFixtureCount) fixtures"
    }

    /// The right panel: how far the evidence goes, and where it stops.
    private var sourcePanel: some View {
        FloodlitCard(palette: palette, depth: .glass) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                HStack(spacing: CoachWorldTokens.Gap.xs) {
                    FloodlitLabel3("How far this goes", palette: palette)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    CoachWorldConfidenceTag(
                        band: model.sourceGameCount == 0
                            ? .unknown
                            : .observations(model.sourceGameCount),
                        palette: palette
                    )
                }
                figureRow("Confidence", "\(model.confidence)%")
                figureRow("Source games", "\(model.sourceGameCount)")
                figureRow("Retained fixtures", "\(model.sourceFixtureCount)")
                Text(
                    "Everything here comes off film the staff has watched. "
                        + "The league's own totals are not shown."
                )
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func figureRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.xs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Text(value)
                .coachWorldFigure(CoachWorldTokens.DisplaySize.panel, weight: .semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label.capitalized), \(value)")
    }

    /// One committing action, bottom-right in the thumb arc.
    private var commitBar: some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            Spacer(minLength: .zero)
            if chrome == nil {
                Button("Back", action: onClose)
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                    .foregroundStyle(palette.contentQuiet.color)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            FloodlitCommittingAction(
                "Into the game plan",
                isEnabled: model.isCurrent,
                action: onContinue
            )
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

private enum FilmMetric {
    /// The handoff's 223pt evidence panel.
    static let panelWidth: CGFloat = 223
    static let situationColumn: CGFloat = 96
    static let splitColumn: CGFloat = 128
    static let filmedColumn: CGFloat = 72
    static let rowHeight: CGFloat = 27
    static let percentScale: Double = 100
}
