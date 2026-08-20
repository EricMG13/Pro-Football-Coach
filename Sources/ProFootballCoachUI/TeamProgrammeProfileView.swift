import SwiftUI

/// Shared profile for every map, standings and schedule organisation.
public struct TeamProgrammeProfileView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: TeamProgrammeProfileReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: TeamProgrammeProfileReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
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
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    identityColumn
                    recordColumn
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                        identityColumn
                            .frame(width: ProfileMetric.identityColumn)
                        recordColumn
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    /// The reference leads with the programme name at display size, over the city and conference,
    /// then the facts a coach would ask about first.
    private var identityColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                FloodlitLabel3(
                    "\(model.cityName) \u{00B7} \(model.regionName)", palette: palette
                )
                Text(model.team.name.uppercased())
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.figure, weight: .bold)
                    .lineLimit(ProfileMetric.nameLines)
                    .minimumScaleFactor(ProfileMetric.nameScaleFloor)
                Text(conferenceLine)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(model.team.name), \(model.cityName), \(model.tier), \(conferenceLine)"
            )
            HStack(alignment: .lastTextBaseline, spacing: CoachWorldTokens.Gap.smPlus) {
                Text(model.record)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.title, weight: .semibold)
                if let rank = model.rank {
                    FloodlitLabel3(rank, palette: palette, tint: palette.actionPrimary.color)
                }
            }
            VStack(alignment: .leading, spacing: .zero) {
                fact("Venue", model.venue.name)
                fact("Prestige", "\(model.prestige)")
                fact("Roster", "\(model.rosterCount)")
                fact("Staff", "\(model.staffCount)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var conferenceLine: String {
        var line = "\(model.tier) \u{00B7} \(model.conference)"
        if let division = model.division { line += " \u{00B7} \(division)" }
        line += " \u{00B7} \(model.seasonLabel)"
        return line
    }

    private func fact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(label, palette: palette)
                .frame(width: ProfileMetric.factKey, alignment: .leading)
            Text(value)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: ProfileMetric.factHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(ProfileMetric.seamAlpha))
                .frame(height: CoachWorldTokens.Shape.hairline)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var recordColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            formSection
            rivalrySection
            traditionsSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The reference's "Form · last six": a bar and a W/L letter per recent result. Not the full
    /// twelve-game schedule -- that duplicates `ScheduleView.swift`, a dedicated screen this app
    /// already has -- and not a fabricated win/loss: `Fixture.score` is always formatted
    /// "homeScore-awayScore" (`CoachWorldTeamProfileProvider.swift`), so combined with `isHome`
    /// the actual result is derivable without guessing.
    private var formSection: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Form \u{00B7} last six", palette: palette)
            if recentResults.isEmpty {
                Text("No games played yet.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
            } else {
                HStack(alignment: .bottom, spacing: CoachWorldTokens.Gap.xs) {
                    ForEach(recentResults, id: \.fixture.id) { entry in
                        formChip(entry)
                    }
                }
            }
        }
    }

    /// The last six PLAYED fixtures, oldest first (reading left to right as recent form usually
    /// does), each paired with whether the controlled programme actually won it.
    private var recentResults: [(fixture: TeamProgrammeProfileReadModel.Fixture, won: Bool)] {
        model.fixtures
            .compactMap { fixture -> (TeamProgrammeProfileReadModel.Fixture, Bool)? in
                guard let score = fixture.score else { return nil }
                let parts = score.split(separator: "\u{2013}")
                guard parts.count == 2,
                      let homeScore = Int(parts[0]),
                      let awayScore = Int(parts[1]) else { return nil }
                let won = fixture.isHome ? homeScore > awayScore : awayScore > homeScore
                return (fixture, won)
            }
            .suffix(ProfileMetric.formGames)
            .map { ($0.0, $0.1) }
    }

    private func formChip(_ entry: (fixture: TeamProgrammeProfileReadModel.Fixture, won: Bool)) -> some View {
        VStack(spacing: CoachWorldTokens.Gap.xxs) {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.hairline)
                .fill(entry.won ? palette.statePositive.color : palette.stateNegative.color)
                .frame(width: ProfileMetric.formChipWidth, height: ProfileMetric.formChipHeight)
            Text(entry.won ? "W" : "L")
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                .foregroundStyle(entry.won ? palette.statePositive.color : palette.stateNegative.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            (entry.won ? "Won" : "Lost") + " versus " + entry.fixture.opponent.name
        )
    }

    /// The reference highlights ONE rival at a time, with a series record and a note neither of
    /// which `Rival` records. This shows the strongest rivalry the model actually has -- origin
    /// and intensity -- rather than reproducing text that isn't backed by a real field.
    @ViewBuilder
    private var rivalrySection: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("The rivalry", palette: palette)
            if let rival = model.rivals.first {
                rivalRow(rival)
            } else {
                Text("No rivalry recorded.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
            }
        }
    }

    private func rivalRow(_ rival: TeamProgrammeProfileReadModel.Rival) -> some View {
        let rivalID = UUID(uuidString: rival.id)
        return FloodlitRow(
            palette: palette,
            action: rivalID.map { id in { onSelectTeam(id) } }
        ) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(rival.team.name.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                        .lineLimit(1)
                    FloodlitLabel3(rival.origin, palette: palette)
                }
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                // Not CoachWorldTokens.Heat.color: intensity is a genuine 40-99 Rating, so the
                // scale mapping is correct, but the middle Heat band is literally
                // `actionPrimary.color` -- the same gold the screen's one committing action uses.
                // A fixed cool tint avoids a rival ever painting as if it were tappable-to-commit.
                FloodlitShareBar(
                    proportion: proportion(of: rival.intensity),
                    tint: palette.stateInfo.color,
                    palette: palette
                )
                .frame(width: ProfileMetric.intensityBar)
                Text("\(rival.intensity)")
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill, weight: .semibold)
                    .frame(width: ProfileMetric.intensityFigure, alignment: .trailing)
            }
        }
        .accessibilityLabel(
            "\(rival.team.name), \(rival.origin), intensity \(rival.intensity)"
        )
    }

    private func proportion(of rating: Int) -> Double {
        let floor = CoachWorldTokens.Heat.scaleFloor
        let ceiling = CoachWorldTokens.Heat.scaleCeiling
        let clamped = min(max(rating, floor), ceiling)
        return Double(clamped - floor) / Double(ceiling - floor)
    }

    private var traditionsSection: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Traditions", palette: palette)
            if model.traditions.isEmpty {
                Text("No traditions recorded.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
            } else {
                ForEach(model.traditions, id: \.self) { tradition in
                    Text(tradition)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, CoachWorldTokens.Gap.hair)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Every figure here is recorded for this programme, not projected.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Back to the league", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum ProfileMetric {
    static let identityColumn: CGFloat = 300
    static let factKey: CGFloat = 72
    static let factHeight: CGFloat = 21
    static let seamAlpha = 0.05
    static let nameLines = 2
    static let nameScaleFloor: CGFloat = 0.6
    static let intensityBar: CGFloat = 60
    static let intensityFigure: CGFloat = 26
    /// The handoff's own "last six" window.
    static let formGames = 6
    static let formChipWidth: CGFloat = 28
    static let formChipHeight: CGFloat = 40
}
