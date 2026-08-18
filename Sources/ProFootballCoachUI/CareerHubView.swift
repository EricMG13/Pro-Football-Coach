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
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header
                    careerViews
                    if let currentJob = model.currentJob {
                        section("CURRENT APPOINTMENT") {
                            jobRow(currentJob)
                            if currentJob.canResign {
                                Button("Resign from appointment", action: onResign)
                                    .buttonStyle(CoachWorldActionButtonStyle(
                                        role: .secondary,
                                        palette: palette
                                    ))
                                    .frame(maxWidth: .infinity,
                                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                                    .accessibilityHint(
                                        "Ends the current appointment and returns the coach to the job search."
                                    )
                            }
                        }
                    }
                    if model.currentJob == nil {
                        section("JOB SEARCH") {
                            Text("No current appointment. The coach remains in the career ledger while seeking the next eligible offer.")
                                .font(CoachWorldTokens.TypeRole.body)
                                .foregroundStyle(palette.contentSecondary.color)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("Continue while seeking", action: onContinue)
                                .buttonStyle(CoachWorldActionButtonStyle(
                                    role: .primary,
                                    palette: palette
                                ))
                                .frame(maxWidth: .infinity,
                                       minHeight: CoachWorldTokens.Shape.minimumTarget)
                        }
                    }
                    section("STAKEHOLDER SUPPORT") {
                        ForEach(model.support) { row in
                            HStack {
                                Text(row.stakeholder)
                                Spacer()
                                Text("\(row.value)/100")
                                    .monospacedDigit()
                                    .fontWeight(.bold)
                            }
                            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(row.stakeholder), \(row.value) out of 100")
                        }
                    }
                    section("JOB HISTORY") {
                        if model.history.isEmpty {
                            CoachWorldSystemState(
                                .empty("No completed appointment is on record yet."),
                                palette: palette
                            )
                        } else {
                            ForEach(model.history) { row in jobRow(row) }
                        }
                    }
                    section("OPPORTUNITIES") {
                        if model.opportunities.isEmpty {
                            CoachWorldSystemState(
                                .empty("No offer is currently on the table."),
                                palette: palette
                            )
                        } else {
                            ForEach(model.opportunities) { opportunity in
                                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                    Text(opportunity.team.name)
                                        .font(.headline)
                                    Text("\(opportunity.tier) · Prestige \(opportunity.prestige)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(palette.contentSecondary.color)
                                    Text("Offered \(opportunity.offered) · Expires \(opportunity.expires)")
                                        .font(.caption)
                                    Text(opportunity.rationale)
                                        .font(.callout)
                                    if opportunity.tier == "Professional" {
                                        Button("Accept professional offer") {
                                            onAcceptOpportunity(opportunity.id)
                                        }
                                        .buttonStyle(CoachWorldActionButtonStyle(
                                            role: .primary,
                                            palette: palette
                                        ))
                                        .frame(maxWidth: .infinity,
                                               minHeight: CoachWorldTokens.Shape.minimumTarget)
                                        .disabled(!opportunity.canAccept)
                                        if let reason = opportunity.unavailableReason, !opportunity.canAccept {
                                            Text(reason)
                                                .font(CoachWorldTokens.TypeRole.caption)
                                                .foregroundStyle(palette.contentSecondary.color)
                                        }
                                    }
                                }
                                .padding(.vertical, CoachWorldTokens.Space.xs)
                                .accessibilityElement(children: .contain)
                            }
                        }
                    }
                }
                .padding(CoachWorldTokens.Space.md)
            }
            .frame(maxWidth: .infinity,
                   alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
            .safeAreaInset(edge: .top) { topBar }
        }
        .accessibilitySortPriority(100)
    }

    private var topBar: some View {
        HStack {
            Button("Office", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            Spacer()
            Text(focus == .careerHub ? "Career Hub" : focus.canonicalName)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Spacer()
            Menu("Views") {
                Button("Career Hub") { onNavigate(.careerHub) }
                Button("Job Security") { onNavigate(.jobSecurity) }
                Button("Stakeholders") { onNavigate(.stakeholders) }
                Button("Promotion Decision") { onNavigate(.promotionDecision) }
                Button("Coaching Carousel") { onNavigate(.coachingCarousel) }
            }
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
            Text(model.status.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity),
            depth: .deep
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(model.coach.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text(model.coach.role)
                .font(CoachWorldTokens.TypeRole.headline)
                .foregroundStyle(palette.contentSecondary.color)
            if let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.stateWarning.color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var careerViews: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(focusDescription)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var focusDescription: String {
        switch focus {
        case .jobSecurity:
            return "Job security is evidenced by your current appointment, stakeholder support, and recorded career history."
        case .stakeholders:
            return "Stakeholder values are the current support ledger; no unrecorded interpretation is shown."
        case .promotionDecision:
            return "Promotion opportunities are shown with their recorded expiry, prestige, and rationale."
        case .coachingCarousel:
            return "The coaching carousel is the durable offer and appointment history for this coach."
        case .jobBoard:
            return "The job board lists the durable career opportunities currently recorded for this coach."
        case .offer:
            return "Offers are shown with their recorded expiry, prestige, and rationale before acceptance."
        case .appointment:
            return "The appointment ledger shows the current job and the recorded history behind it."
        default:
            return "Your employment, support, history, and opportunities share one durable career ledger."
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            content()
        }
        .padding(CoachWorldTokens.Space.sm)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
        )
    }

    private func jobRow(_ row: CareerHubReadModel.JobRow) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(row.team.name)
                .font(.headline)
            Text("\(row.tier) · Started \(row.started)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.contentSecondary.color)
            if let ended = row.ended, let reason = row.reason {
                Text("Ended \(ended) · \(reason)")
                    .font(.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
        }
        .padding(.vertical, CoachWorldTokens.Space.xs)
        .accessibilityElement(children: .combine)
    }
}
