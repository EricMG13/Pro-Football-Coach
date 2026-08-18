import SwiftUI

public struct TeamHealthView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: TeamHealthReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: TeamHealthReadModel,
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
                if dynamicTypeSize.isAccessibilitySize {
                    readinessTable
                    casePanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        readinessTable
                        casePanel
                            .frame(width: HealthMetric.panelWidth)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { alertBar }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(
                "Team health \u{00B7} \(model.weekLabel) \u{00B7} "
                    + "\(model.players.count) on the readiness list",
                palette: palette
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(
                "Condition \(model.averageCondition)%",
                palette: palette,
                tint: CoachWorldTokens.Heat.color(for: model.averageCondition, palette: palette)
            )
        }
    }

    /// The reference's readiness table: position, name, status, the evidence as a bar, the figure.
    ///
    /// Ordered worst first. A readiness list sorted by squad number makes the coach hunt for the
    /// three names that matter; the reference's own ordering puts the concern at the top.
    private var readinessTable: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("Pos", palette: palette)
                    .frame(width: HealthMetric.positionColumn, alignment: .leading)
                FloodlitLabel3("Player", palette: palette)
                    .frame(maxWidth: .infinity, alignment: .leading)
                FloodlitLabel3("Status", palette: palette)
                    .frame(width: HealthMetric.statusColumn, alignment: .leading)
                FloodlitLabel3("Condition", palette: palette)
                    .frame(width: HealthMetric.evidenceColumn, alignment: .trailing)
            }
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .frame(minHeight: HealthMetric.headerHeight)
            .accessibilityHidden(true)
            if model.players.isEmpty {
                CoachWorldSystemState(
                    .empty("No readiness evidence is recorded for this squad."),
                    palette: palette
                )
            } else {
                ForEach(orderedPlayers) { player in
                    readinessRow(player)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Worst condition first, then by name so the order is stable across snapshots.
    private var orderedPlayers: [TeamHealthReadModel.PlayerStatus] {
        model.players.sorted {
            $0.condition == $1.condition ? $0.name < $1.name : $0.condition < $1.condition
        }
    }

    private func readinessRow(_ player: TeamHealthReadModel.PlayerStatus) -> some View {
        let tint = CoachWorldTokens.Heat.color(for: player.condition, palette: palette)
        return HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            Text(player.position.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                .tracking(
                    CoachWorldTokens.DisplaySize.tracking(
                        HealthMetric.positionTracking, at: CoachWorldTokens.DisplaySize.pill
                    )
                )
                .foregroundStyle(palette.stateInfo.color)
                .lineLimit(1)
                .frame(width: HealthMetric.positionColumn, alignment: .leading)
            Text(player.name)
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(player.availability.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                .tracking(
                    CoachWorldTokens.DisplaySize.tracking(
                        HealthMetric.statusTracking, at: CoachWorldTokens.DisplaySize.flag
                    )
                )
                .foregroundStyle(availabilityTint(player))
                .lineLimit(1)
                .frame(width: HealthMetric.statusColumn, alignment: .leading)
            FloodlitShareBar(
                proportion: Double(player.condition) / HealthMetric.percentScale,
                tint: tint,
                palette: palette
            )
            .frame(width: HealthMetric.barColumn)
            Text("\(player.condition)%")
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: HealthMetric.figureColumn, alignment: .trailing)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: HealthMetric.rowHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(HealthMetric.seamAlpha))
                .frame(height: CoachWorldTokens.Shape.hairline)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.position) \(player.name), \(player.availability), "
                + "condition \(player.condition) percent, fatigue \(player.fatigue) percent. "
                + player.statusDetail
        )
    }

    /// An availability that is not "available" is the thing this screen exists to show, so it
    /// carries the warning tone rather than the quiet one.
    private func availabilityTint(_ player: TeamHealthReadModel.PlayerStatus) -> Color {
        player.availability.lowercased().hasPrefix("available")
            ? palette.contentQuiet.color
            : palette.stateWarning.color
    }

    /// The reference's injury card: the one player whose availability is most in question, and the
    /// evidence behind it. There is no treatment plan or return date in this build, so the card
    /// carries what is recorded and says so rather than filling the slot with a projection.
    private var casePanel: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                if let subject = caseSubject {
                    FloodlitLabel3("The case to watch", palette: palette)
                    Text(subject.name)
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.title, weight: .bold
                            )
                        )
                        .lineLimit(HealthMetric.nameLines)
                    Text("\(subject.position) \u{00B7} \(subject.availability)")
                        .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill))
                        .foregroundStyle(palette.contentSecondary.color)
                    caseRow("Condition", "\(subject.condition)%", value: subject.condition)
                    caseRow(
                        "Fatigue",
                        "\(subject.fatigue)%",
                        value: HealthMetric.fullPercent - subject.fatigue
                    )
                    Text(subject.statusDetail)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    FloodlitLabel3("The case to watch", palette: palette)
                    Text("Nobody is carrying anything.")
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The player the card is about: the least available, worst-conditioned name on the list.
    private var caseSubject: TeamHealthReadModel.PlayerStatus? {
        orderedPlayers.first { !$0.availability.lowercased().hasPrefix("available") }
            ?? orderedPlayers.first
    }

    private func caseRow(_ label: String, _ value: String, value proportionOf: Int) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            FloodlitLabel3(label, palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitShareBar(
                proportion: Double(proportionOf) / HealthMetric.percentScale,
                tint: CoachWorldTokens.Heat.color(for: proportionOf, palette: palette),
                palette: palette
            )
            .frame(width: HealthMetric.caseBarColumn)
            Text(value)
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill, weight: .semibold))
                .frame(width: HealthMetric.figureColumn, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    /// The reference's alert bar, full width above the home indicator.
    ///
    /// It states what is actually wrong. When nothing is, it says so quietly rather than
    /// disappearing: this is the strip that carries the committing action, and a control that
    /// moves position depending on the squad's health is worse than a calm sentence.
    private var alertBar: some View {
        let concerns = [
            model.injuryCount > 0 ? "\(model.injuryCount) injured" : nil,
            model.suspensionCount > 0 ? "\(model.suspensionCount) suspended" : nil,
        ].compactMap { $0 }
        let isCalm = concerns.isEmpty
        return HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            if !isCalm {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: HealthMetric.alertIcon, weight: .semibold))
                    .foregroundStyle(palette.stateWarning.color)
                    .accessibilityHidden(true)
            }
            Text(
                isCalm
                    ? "Everyone is available. Average condition \(model.averageCondition)%."
                    : concerns.joined(separator: " \u{00B7} ")
                        + ". Average condition \(model.averageCondition)%."
            )
            .font(CoachWorldTokens.TypeRole.callout)
            .foregroundStyle(isCalm ? palette.contentSecondary.color : palette.contentPrimary.color)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction(
                "Continue",
                isEnabled: model.canContinue,
                action: onContinue
            )
            .accessibilityHint(model.continueReason ?? "")
        }
        .padding(.vertical, CoachWorldTokens.Pad.alert.v)
        .padding(.horizontal, CoachWorldTokens.Pad.alert.h)
        .frame(maxWidth: .infinity)
        .background(CoachWorldCutCorner.alert.fill(CoachWorldTokens.Floodlit.glassFlatDeep.color))
        .overlay {
            CoachWorldCutCorner.alert.stroke(
                isCalm
                    ? Color.white.opacity(CoachWorldTokens.Glass.line)
                    : palette.stateWarning.color.opacity(HealthMetric.alertBorderAlpha),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .padding(.top, CoachWorldTokens.Gap.xs)
    }
}

private enum HealthMetric {
    /// The handoff's 223pt case panel.
    static let panelWidth: CGFloat = 223
    static let positionColumn: CGFloat = 42
    static let statusColumn: CGFloat = 64
    static let evidenceColumn: CGFloat = 96
    static let barColumn: CGFloat = 48
    static let figureColumn: CGFloat = 44
    static let caseBarColumn: CGFloat = 60
    static let rowHeight: CGFloat = 27
    static let headerHeight: CGFloat = 17
    static let alertIcon: CGFloat = 19
    static let positionTracking: CGFloat = 0.08
    static let statusTracking: CGFloat = 0.14
    static let seamAlpha = 0.05
    static let alertBorderAlpha = 0.45
    static let percentScale: Double = 100
    static let fullPercent = 100
    static let nameLines = 2
}
