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
    public let canonicalID: Int
    /// Route switching between the four career entries. The shared chrome's sibling row now
    /// offers this, so the surface draws no menu of its own -- the closure stays wired because the
    /// call sites pass it and a bare-stage caller still needs somewhere to send the intent.
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onAcceptOpportunity: (String) -> Void
    public let onResign: () -> Void
    public let onContinue: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var receiptIsFocused: Bool
    @State private var pendingOpportunity: CareerHubReadModel.OpportunityRow?
    @State private var showingResignConfirmation = false
    @State private var selectedOpportunityID: String?

    public init(
        model: CareerHubReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        focus: CoachWorldScreenID = .careerHub,
        /// The canonical destination this rendering *is*, stated rather than taken from `focus`.
        ///
        /// Eight callers, three identities. Stakeholders is 54 and Promotion Decision is 55, each
        /// with its own contract row; Job Board, Offer, Appointment, Job Security and Coaching
        /// Carousel are aliases and inherit 52 by passing nothing.
        canonicalID: Int = 52,
        onNavigate: @escaping (CoachWorldScreenID) -> Void = { _ in },
        onAcceptOpportunity: @escaping (String) -> Void = { _ in },
        onResign: @escaping () -> Void = {},
        onContinue: @escaping () -> Void = {}
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.focus = focus
        self.canonicalID = canonicalID
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
        .alert(item: $pendingOpportunity) { opportunity in
            let consequence = model.currentJob == nil
                ? "start this appointment"
                : "end the current appointment and start this one"
            return Alert(
                title: Text("Accept \(opportunity.team.name)?"),
                message: Text(
                    "This offer is \(opportunity.tier) with prestige \(opportunity.prestige). "
                        + "Accepting will \(consequence)."
                ),
                primaryButton: .default(
                    Text("Accept \(opportunity.team.name) · \(consequence)")
                ) {
                    onAcceptOpportunity(opportunity.id)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(
            resignationTitle,
            isPresented: $showingResignConfirmation
        ) {
            Button("Resign · return to job search", role: .destructive, action: onResign)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This ends the current appointment and returns the coach to the job search.")
        }
        .onChange(of: statusMessage) { _, message in
            if message != nil { receiptIsFocused = true }
        }
        .accessibilitySortPriority(100)
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: canonicalID) }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityFocused($receiptIsFocused)
                        .accessibilityIdentifier("career-receipt")
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

    private var resignationTitle: String {
        let appointmentName = model.currentJob?.team.name ?? "this appointment"
        return "Resign from \(appointmentName)?"
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
                    opportunityWorkspace
                case .jobBoard, .offer, .appointment:
                    opportunityWorkspace
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
        case .jobBoard, .offer, .appointment: "Current opportunities"
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

    /// Offers are selected locally; only the evidence panel can open the accepting confirmation.
    @ViewBuilder
    private var opportunityWorkspace: some View {
        if model.opportunities.isEmpty {
            Text("No offer is currently on the table.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                    opportunityList
                    selectedOpportunityEvidence
                }
            } else {
                HStack(alignment: .top, spacing: CoachWorldTokens.Gap.md) {
                    opportunityList
                        .frame(width: 210, alignment: .leading)
                    selectedOpportunityEvidence
                }
            }
        }
    }

    private var selectedOpportunity: CareerHubReadModel.OpportunityRow? {
        model.opportunities.first { $0.id == selectedOpportunityID }
            ?? model.opportunities.first
    }

    private var opportunityList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Offers", palette: palette)
            ForEach(model.opportunities) { opportunity in
                let isSelected = selectedOpportunity?.id == opportunity.id
                Button {
                    selectedOpportunityID = opportunity.id
                } label: {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                        Text(opportunity.team.name.uppercased())
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                                )
                            )
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(opportunity.canAccept
                             ? "Available"
                             : "Unavailable · \(opportunity.unavailableReason ?? "No reason recorded")")
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(
                                opportunity.canAccept
                                    ? palette.contentSecondary.color
                                    : palette.contentQuiet.color
                            )
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                           alignment: .leading)
                    .padding(.horizontal, CoachWorldTokens.Space.sm)
                    .background(
                        isSelected
                            ? palette.collegeIdentity.color.opacity(0.18)
                            : palette.raised.color.opacity(0.45)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? palette.collegeIdentity.color : .clear,
                                lineWidth: CoachWorldTokens.Shape.hairline
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityHint(
                    opportunity.canAccept
                        ? "Selects this offer to review its evidence."
                        : "Selects this offer. It cannot be accepted: \(opportunity.unavailableReason ?? "no reason recorded")."
                )
            }
        }
    }

    @ViewBuilder
    private var selectedOpportunityEvidence: some View {
        if let opportunity = selectedOpportunity {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("Selected offer", palette: palette,
                               tint: palette.collegeIdentity.color)
                Text(opportunity.team.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.action, weight: .bold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                FloodlitCostLine(
                    cost: "\(opportunity.tier) \u{00B7} prestige \(opportunity.prestige)",
                    exposure: "offered \(opportunity.offered) · expires \(opportunity.expires)",
                    consequence: "Rationale: \(opportunity.rationale)",
                    palette: palette
                )
                Text(currentJobConsequence)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                if opportunity.canAccept {
                    FloodlitCommittingAction("Accept \(opportunity.team.name)") {
                        pendingOpportunity = opportunity
                    }
                    .accessibilityHint("Opens a confirmation naming the appointment consequence.")
                } else {
                    Text(opportunity.unavailableReason ?? "This offer cannot be accepted.")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
        } else {
            Text("Select an offer to review its evidence.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
        }
    }

    private var currentJobConsequence: String {
        model.currentJob == nil
            ? "Consequence: starts a new appointment."
            : "Consequence: ends \(model.currentJob?.team.name ?? "the current appointment") and starts this one."
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
                Button("Resign") { showingResignConfirmation = true }
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
            FloodlitCommittingAction("Advance week", action: onContinue)
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
