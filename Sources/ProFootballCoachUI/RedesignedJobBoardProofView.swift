#if DEBUG
import SwiftUI

/// A contained proof of the redesigned career offer flow.
///
/// This is intentionally not the live `JobBoardView`: the proof owns only local selection and
/// receipt state, so reviewing the interaction cannot mutate a save or hide a missing engine fact.
struct RedesignedJobBoardProofView: View {
    private enum Constants {
        static let activeOfferID = "proof-southern-state-offer"
        static let unavailableOfferID = "proof-lake-county-offer"
        static let currentJobID = "proof-current-job"
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var receiptIsFocused: Bool
    @State private var selectedOpportunityID = Constants.activeOfferID
    @State private var hasAcceptedOffer = false
    @State private var showingAcceptance = false
    @State private var statusMessage: String?

    private let model = Self.sampleModel
    private let palette = CoachWorldTokens.dark

    var body: some View {
        CoachWorldFloodlitStage(palette: palette) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibleLayout
                } else {
                    standardLayout
                }
            }
            .padding(.horizontal, CoachWorldTokens.Stage.contentLeading)
            .padding(.top, CoachWorldTokens.Frame.topInset)
            .padding(.bottom, CoachWorldTokens.Frame.bottomInset)
        }
        .alert("Accept this offer?", isPresented: $showingAcceptance) {
            Button(acceptanceButtonTitle) {
                acceptSelectedOpportunity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(acceptanceMessage)
        }
        .accessibilityIdentifier("redesigned-job-board-proof")
    }

    private var standardLayout: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
            header
            HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                offerList
                    .frame(width: 250, alignment: .leading)
                detailPanel
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
                header
                offerList
                detailPanel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                    headerTitle
                    headerCoach
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
                    headerTitle
                    Spacer(minLength: CoachWorldTokens.Gap.sm)
                    headerCoach
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(100)
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            FloodlitLabel3("Career / Job board", palette: palette, tint: palette.collegeIdentity.color)
            Text("SAMPLE CAREER")
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.screen, weight: .black)
                .foregroundStyle(palette.contentPrimary.color)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var headerCoach: some View {
        VStack(
            alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
            spacing: CoachWorldTokens.Gap.hair
        ) {
            Text(model.coach.name.uppercased())
                .font(CoachWorldTokens.TypeRole.headline)
            Text(model.status)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var offerList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Offers", palette: palette)
            if hasAcceptedOffer {
                emptyState
            } else {
                ForEach(model.opportunities) { opportunity in
                    opportunityRow(opportunity)
                }
            }
        }
        .accessibilitySortPriority(90)
    }

    private func opportunityRow(_ opportunity: CareerHubReadModel.OpportunityRow) -> some View {
        let isSelected = selectedOpportunityID == opportunity.id
        return Button {
            guard opportunity.canAccept else { return }
            selectedOpportunityID = opportunity.id
            statusMessage = nil
        } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
                    Text(opportunity.team.name.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.action, weight: .bold)
                        .lineLimit(1)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    if isSelected {
                        Text("SELECTED")
                            .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                            .foregroundStyle(palette.collegeIdentity.color)
                    }
                }
                FloodlitCostLine(
                    cost: opportunity.tier,
                    exposure: "expires \(opportunity.expires)",
                    consequence: opportunity.rationale,
                    palette: palette
                )
                if let reason = opportunity.unavailableReason {
                    Text(reason)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .padding(.vertical, CoachWorldTokens.Pad.row.v)
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget, alignment: .leading)
            .background(CoachWorldCutCorner.row.fill(palette.work.color.opacity(0.72)))
            .overlay {
                CoachWorldCutCorner.row.stroke(
                    isSelected ? palette.collegeIdentity.color : Color.white.opacity(0.18),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .opacity(opportunity.canAccept ? 1 : CoachWorldTokens.Motion.disabledOpacity)
        }
        .buttonStyle(.plain)
        .disabled(!opportunity.canAccept)
        .accessibilityLabel(opportunity.team.name)
        .accessibilityValue(
            opportunity.canAccept
                ? (isSelected
                    ? "Selected. \(opportunity.tier). Expires \(opportunity.expires)."
                    : opportunity.tier)
                : "Unavailable. \(opportunity.unavailableReason ?? "Not actionable")"
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("offer-\(opportunity.id)")
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let opportunity = selectedOpportunity, !hasAcceptedOffer {
            FloodlitCard(palette: palette, depth: .deep) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                    FloodlitLabel3("Selected offer", palette: palette, tint: palette.collegeIdentity.color)
                    Text(opportunity.team.name.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.title, weight: .black)
                        .lineLimit(1)
                    Text("\(opportunity.tier) appointment")
                        .font(CoachWorldTokens.TypeRole.headline)
                        .foregroundStyle(palette.contentSecondary.color)

                    facts(opportunity)

                    Text(opportunity.rationale)
                        .font(CoachWorldTokens.TypeRole.body)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Spacer(minLength: CoachWorldTokens.Gap.xs)
                        Button(acceptanceButtonTitle) {
                            showingAcceptance = true
                        }
                        .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                        .disabled(!opportunity.canAccept)
                        .accessibilityIdentifier("accept-selected-offer")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            acceptedState
        }
    }

    private func facts(_ opportunity: CareerHubReadModel.OpportunityRow) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            fact("Tier", opportunity.tier)
            fact("Prestige", "\(opportunity.prestige)")
            fact("Offered", opportunity.offered)
            fact("Expires", opportunity.expires)
            fact("Consequence", currentJobConsequence)
        }
    }

    private func fact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(label, palette: palette)
                .frame(width: 82, alignment: .leading)
            Text(value)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentPrimary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            Text("No open offers")
                .font(CoachWorldTokens.TypeRole.headline)
            Text("The accepted appointment is now the active career decision. This proof has not changed a save.")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CoachWorldTokens.Pad.card.h)
        .frame(maxWidth: .infinity, alignment: .leading)
        .coachWorldFloodlitPanel(
            fill: palette.work.color.opacity(0.72),
            border: Color.white.opacity(0.18),
            depth: .glass,
            shape: CoachWorldCutCorner.card
        )
    }

    private var acceptedState: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                FloodlitLabel3("Success", palette: palette, tint: palette.stateLive.color)
                if let statusMessage {
                    receipt(statusMessage)
                }
                Button("Reset proof", action: resetProof)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
                    .accessibilityIdentifier("reset-proof")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func receipt(_ message: String) -> some View {
        Text(message)
            .font(CoachWorldTokens.TypeRole.body.weight(.semibold))
            .foregroundStyle(palette.stateLive.color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityFocused($receiptIsFocused)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("proof-receipt")
    }

    private var selectedOpportunity: CareerHubReadModel.OpportunityRow? {
        model.opportunities.first { $0.id == selectedOpportunityID }
    }

    private var currentJobConsequence: String {
        guard let currentJob = model.currentJob else { return "Starts a new appointment" }
        return "Ends \(currentJob.team.name) appointment"
    }

    private var acceptanceButtonTitle: String {
        guard let opportunity = selectedOpportunity else { return "Accept offer" }
        if let currentJob = model.currentJob {
            return "Accept \(opportunity.team.name) · leave \(currentJob.team.name)"
        }
        return "Accept \(opportunity.team.name) · start appointment"
    }

    private var acceptanceMessage: String {
        guard let opportunity = selectedOpportunity else { return "No offer is selected." }
        return "This accepts the \(opportunity.team.name) offer and \(currentJobConsequence.lowercased())."
    }

    private func acceptSelectedOpportunity() {
        guard let opportunity = selectedOpportunity, opportunity.canAccept else { return }
        hasAcceptedOffer = true
        statusMessage = "Prototype receipt: accepted \(opportunity.team.name) offer. No save was changed."
        receiptIsFocused = true
    }

    private func resetProof() {
        hasAcceptedOffer = false
        selectedOpportunityID = Constants.activeOfferID
        statusMessage = nil
        receiptIsFocused = false
    }

    private static let sampleModel = CareerHubReadModel(
        snapshotID: "proof-career-snapshot",
        provenance: .sample,
        world: CoachWorldSampleData.world,
        coach: CoachWorldSampleData.headCoach,
        status: "Employed",
        currentJob: .init(
            id: Constants.currentJobID,
            team: CoachWorldSampleData.homeTeam,
            tier: "College",
            started: "Week 1",
            canResign: true
        ),
        history: [],
        opportunities: [
            .init(
                id: Constants.activeOfferID,
                team: CoachWorldSampleData.awayTeam,
                tier: "Professional",
                offered: "Week 10",
                expires: "Week 12",
                prestige: 82,
                rationale: "Sustained college success",
                canAccept: true
            ),
            .init(
                id: Constants.unavailableOfferID,
                team: CoachWorldTeamReference(
                    stableID: "sample-lake-county",
                    name: "Lake County",
                    abbreviation: "LAK"
                ),
                tier: "College",
                offered: "Week 8",
                expires: "Week 9",
                prestige: 64,
                rationale: "Staff recommendation",
                canAccept: false,
                unavailableReason: "Only professional offers are actionable here."
            ),
        ],
        support: []
    )
}
#endif
