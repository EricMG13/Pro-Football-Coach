import SwiftUI

/// A live career ledger backed by the employment transaction boundary. Every displayed row gives
/// the coach a durable explanation of current status, support, history, and offers.
public struct CareerHubView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: CareerHubReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let focus: CoachWorldScreenID
    /// Route switching between the four career entries. The shared chrome's sibling row now
    /// offers this, so the surface draws no menu of its own -- the closure stays wired because the
    /// call sites pass it and a bare-stage caller still needs somewhere to send the intent.
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onAcceptOpportunity: (String) -> Void
    public let onResign: () -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: CareerHubReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        focus: CoachWorldScreenID = .careerHub,
        onNavigate: @escaping (CoachWorldScreenID) -> Void = { _ in },
        onAcceptOpportunity: @escaping (String) -> Void = { _ in },
        onResign: @escaping () -> Void = {},
        onContinue: @escaping () -> Void = {}
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.focus = focus
        self.onNavigate = onNavigate
        self.onAcceptOpportunity = onAcceptOpportunity
        self.onResign = onResign
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
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    identityColumn
                    standingColumn
                    focusPanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                        identityColumn
                            .frame(width: CareerMetric.identityColumn)
                        standingColumn
                            .frame(width: CareerMetric.standingColumn)
                        focusPanel
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    /// The coach, at the size the reference sets: the role as a label, the name as display type,
    /// and the appointment as facts beneath it.
    private var identityColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3(appointmentLabel, palette: palette)
            Text(model.coach.name.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.figure, weight: .bold))
                .lineLimit(CareerMetric.nameLines)
                .minimumScaleFactor(CareerMetric.nameScaleFloor)
            VStack(alignment: .leading, spacing: .zero) {
                fact("Status", model.status)
                if let job = model.currentJob {
                    fact("Programme", job.team.name)
                    fact("Tier", job.tier)
                    fact("Since", job.started)
                } else {
                    fact("Programme", "Between appointments")
                }
                fact("Appointments", historyLabel)
            }
        }
        .accessibilityElement(children: .contain)
        .coachWorldEntrance()
    }

    private var appointmentLabel: String {
        guard let job = model.currentJob else { return "Between appointments" }
        return "\(model.coach.role) \u{00B7} \(job.team.name)"
    }

    private var historyLabel: String {
        let count = model.history.count
        if count == 0 { return "this is the first" }
        return count == 1 ? "one before this" : "\(count) before this"
    }

    private func fact(_ key: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(key, palette: palette)
                .frame(width: CareerMetric.factKey, alignment: .leading)
            Text(value)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: CareerMetric.factHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(CareerMetric.seamAlpha))
                .frame(height: CoachWorldTokens.Shape.hairline)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key), \(value)")
    }

    /// Standing: who is behind the coach, as a ring each. Support is a 0-100 ledger, so the ring
    /// is read against that whole rather than the 40-99 rating scale the Heat bands describe.
    private var standingColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Standing", palette: palette)
            if model.support.isEmpty {
                Text("No support is recorded yet.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
            } else {
                ForEach(model.support) { row in
                    HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
                        CoachWorldRatingRing(
                            value: row.value,
                            ceiling: CareerMetric.supportCeiling,
                            floor: 0,
                            diameter: CareerMetric.ringDiameter,
                            palette: palette
                        )
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                            Text(row.stakeholder.uppercased())
                                .font(
                                    CoachWorldTokens.display(
                                        CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                                    )
                                )
                                .lineLimit(1)
                            Text("\(row.value) of \(CareerMetric.supportCeiling)")
                                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.flag))
                                .foregroundStyle(palette.contentQuiet.color)
                        }
                        Spacer(minLength: .zero)
                    }
                    .frame(minHeight: CareerMetric.standingRowHeight)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(row.stakeholder), \(row.value) out of \(CareerMetric.supportCeiling)"
                    )
                }
            }
        }
    }

    /// The third column changes with the route. Four registry entries share this composition, and
    /// what distinguishes them is which evidence the panel holds -- not a different screen.
    private var focusPanel: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3(
                    focusTitle, palette: palette, tint: palette.actionPrimary.color
                )
                switch focus {
                case .stakeholders:
                    Text(
                        "These are the current support figures, and nothing beyond them. "
                            + "No interpretation is recorded."
                    )
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                case .promotionDecision:
                    opportunityRows
                default:
                    historyRows
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var focusTitle: String {
        switch focus {
        case .jobSecurity: "What the board can see"
        case .stakeholders: "Who is behind you"
        case .promotionDecision: "What is on the table"
        default: "What is on the record"
        }
    }

    @ViewBuilder
    private var historyRows: some View {
        if model.history.isEmpty {
            Text("No completed appointment is on record yet.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            ForEach(model.history) { row in
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(row.team.name.uppercased())
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                            )
                        )
                        .lineLimit(1)
                    Text(historyLine(row))
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.team.name). \(historyLine(row))")
            }
        }
    }

    private func historyLine(_ row: CareerHubReadModel.JobRow) -> String {
        var line = "\(row.tier) \u{00B7} from \(row.started)"
        if let ended = row.ended { line += " to \(ended)" }
        if let reason = row.reason { line += " \u{00B7} \(reason)" }
        return line
    }

    /// An offer, with what it costs to take it. The interface never says which to pick.
    @ViewBuilder
    private var opportunityRows: some View {
        if model.opportunities.isEmpty {
            Text("No offer is currently on the table.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            ForEach(model.opportunities) { opportunity in
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(opportunity.team.name.uppercased())
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                            )
                        )
                        .lineLimit(1)
                    FloodlitCostLine(
                        cost: "\(opportunity.tier) \u{00B7} prestige \(opportunity.prestige)",
                        exposure: "expires \(opportunity.expires)",
                        consequence: opportunity.rationale,
                        palette: palette
                    )
                    if opportunity.canAccept {
                        Button("Take it") { onAcceptOpportunity(opportunity.id) }
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                                )
                            )
                            .foregroundStyle(palette.actionPrimary.color)
                            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget,
                                   alignment: .leading)
                    } else if let reason = opportunity.unavailableReason {
                        Text(reason)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentQuiet.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// The footer carries whichever action the coach's actual position allows: resign when
    /// appointed and permitted, continue when not.
    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(footerNote)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            if model.currentJob?.canResign == true {
                Button("Resign", action: onResign)
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .foregroundStyle(palette.contentQuiet.color)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                    .accessibilityHint(
                        "Ends the current appointment and returns the coach to the job search."
                    )
            }
            FloodlitCommittingAction("Continue", action: onContinue)
        }
        .floodlitFooterStrip(palette: palette)
    }

    private var footerNote: String {
        model.currentJob == nil
            ? "No current appointment. The ledger stays open while you look."
            : "Everything here is recorded. None of it is a prediction about your job."
    }
}

private enum CareerMetric {
    /// The handoff's 300pt identity column and 190pt standing column.
    static let identityColumn: CGFloat = 300
    static let standingColumn: CGFloat = 190
    static let factKey: CGFloat = 82
    static let factHeight: CGFloat = 21
    static let ringDiameter: CGFloat = 34
    static let standingRowHeight: CGFloat = 34
    static let nameLines = 2
    static let nameScaleFloor: CGFloat = 0.6
    static let seamAlpha = 0.05
    /// Stakeholder support is a 0-100 ledger, not a 40-99 rating.
    static let supportCeiling = 100
}
