import SwiftUI

/// A roster-scoped development ledger. It shows recorded deltas only; potential and projections
/// remain outside the read model until an authoritative plan exists.
public struct DevelopmentPlanView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RosterReadModel
    public let statusMessage: String?
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var openPlayerID: String?

    public init(
        model: RosterReadModel,
        statusMessage: String? = nil,
        initialPlayerID: String? = nil,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        _openPlayerID = State(initialValue: initialPlayerID)
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(dynamicTypeSize.isAccessibilitySize ? 100 : 90)
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
                if model.players.isEmpty {
                    CoachWorldSystemState(
                        .empty(
                            "No development evidence. No roster records are available "
                                + "for this checkpoint."
                        ),
                        palette: palette
                    )
                } else if dynamicTypeSize.isAccessibilitySize {
                    subjectBlock
                    movementList
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                        subjectBlock
                            .frame(width: DevelopmentMetric.subjectColumn)
                        movementList
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(
                "Development \u{00B7} \(model.seasonLabel) \u{00B7} \(model.weekLabel)",
                palette: palette
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3("Earned, not projected", palette: palette)
        }
    }

    /// The reference leads this surface with one player: the number and year as a label, the name
    /// at display size, the position and overall beneath, then the dial.
    @ViewBuilder
    private var subjectBlock: some View {
        if let player = openPlayer {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    FloodlitLabel3(
                        "No. \(player.number) \u{00B7} \(player.academicYear) \u{00B7} "
                            + player.rosterRole,
                        palette: palette
                    )
                    Text(player.person.name.uppercased())
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.figure, weight: .bold
                            )
                        )
                        .lineLimit(DevelopmentMetric.nameLines)
                        .minimumScaleFactor(DevelopmentMetric.nameScaleFloor)
                    Text("\(player.position.uppercased()) \u{00B7} \(player.overall) overall")
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.row, weight: .bold
                            )
                        )
                        .foregroundStyle(palette.actionPrimary.color)
                        .lineLimit(1)
                }
                HStack(spacing: CoachWorldTokens.Gap.xl) {
                    FloodlitAttributeDial(
                        rating: player.overall,
                        title: player.position,
                        diameter: DevelopmentMetric.dialDiameter,
                        palette: palette
                    )
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                        FloodlitLabel3("Since August", palette: palette)
                        Text(deltaLabel(player.developmentDelta))
                            .font(
                                CoachWorldTokens.figure(
                                    CoachWorldTokens.DisplaySize.title, weight: .semibold
                                )
                            )
                            .foregroundStyle(deltaTint(player.developmentDelta))
                        Text("Condition \(player.condition)")
                            .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill))
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private var openPlayer: RosterReadModel.PlayerRow? {
        model.players.first { $0.stableID == openPlayerID } ?? orderedPlayers.first
    }

    /// The reference draws a coach-hours allocator here, twelve hours a week against attributes.
    /// This build records **what movement has already happened**, and nothing that would let a
    /// coach spend hours -- so the column states the movement rather than offering a control that
    /// cannot be committed. `04` section 4.4: a dial with nothing behind it is worse than a list.
    private var movementList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("Who has moved", palette: palette)
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                FloodlitLabel3(movedSummary, palette: palette)
            }
            ForEach(orderedPlayers) { player in
                FloodlitRow(
                    isSelected: openPlayer?.stableID == player.stableID,
                    palette: palette,
                    action: { openPlayerID = player.stableID }
                ) {
                    HStack(spacing: CoachWorldTokens.Gap.md) {
                        Text(player.position.uppercased())
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.pill, weight: .bold
                                )
                            )
                            .foregroundStyle(palette.stateInfo.color)
                            .lineLimit(1)
                            .frame(width: DevelopmentMetric.positionColumn, alignment: .leading)
                        Text(player.person.name)
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.row, weight: .bold
                                )
                            )
                            .lineLimit(1)
                        Spacer(minLength: CoachWorldTokens.Gap.xs)
                        Text("\(player.overall)")
                            .font(
                                CoachWorldTokens.figure(
                                    CoachWorldTokens.DisplaySize.row, weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                CoachWorldTokens.Heat.color(for: player.overall, palette: palette)
                            )
                            .frame(width: DevelopmentMetric.figureColumn, alignment: .trailing)
                        Text(deltaLabel(player.developmentDelta))
                            .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill))
                            .foregroundStyle(deltaTint(player.developmentDelta))
                            .frame(width: DevelopmentMetric.deltaColumn, alignment: .trailing)
                    }
                }
                .accessibilityLabel(
                    "\(player.position) \(player.person.name), \(player.overall) overall, "
                        + "development \(spokenDelta(player.developmentDelta))"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Movement first, largest first, then the rest in roster order. A development list ordered by
    /// squad number buries the only rows that changed.
    private var orderedPlayers: [RosterReadModel.PlayerRow] {
        model.players.sorted { lhs, rhs in
            let left = abs(lhs.developmentDelta ?? 0)
            let right = abs(rhs.developmentDelta ?? 0)
            if left != right { return left > right }
            return lhs.person.name < rhs.person.name
        }
    }

    private var movedSummary: String {
        let moved = model.players.filter { ($0.developmentDelta ?? 0) != 0 }.count
        if moved == 0 { return "nobody has moved yet" }
        return moved == 1 ? "1 player has moved" : "\(moved) players have moved"
    }

    /// A recorded change, or an em dash. Never a projection: potential is hidden truth.
    private func deltaLabel(_ delta: Int?) -> String {
        guard let delta, delta != 0 else { return "\u{2014}" }
        return delta > 0 ? "+\(delta)" : "\(delta)"
    }

    private func spokenDelta(_ delta: Int?) -> String {
        guard let delta, delta != 0 else { return "unchanged" }
        return delta > 0 ? "up \(delta)" : "down \(abs(delta))"
    }

    private func deltaTint(_ delta: Int?) -> Color {
        guard let delta, delta != 0 else { return palette.contentQuiet.color }
        return delta > 0 ? palette.statePositive.color : palette.stateNegative.color
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Everything here was earned since August. Nothing is projected.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum DevelopmentMetric {
    /// The handoff's 250pt subject column and 212pt dial.
    static let subjectColumn: CGFloat = 250
    static let dialDiameter: CGFloat = 130
    static let positionColumn: CGFloat = 44
    static let figureColumn: CGFloat = 34
    static let deltaColumn: CGFloat = 34
    static let nameLines = 2
    static let nameScaleFloor: CGFloat = 0.6
}
