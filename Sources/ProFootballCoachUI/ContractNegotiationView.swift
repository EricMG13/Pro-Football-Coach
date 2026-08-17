import SwiftUI
import FootballSimCore

/// The persistent offer/counter surface. Every mutation is a `ProManagementAction`; this view
/// never edits a player or cap ledger directly.
public struct ContractNegotiationView: View {
    public let model: ProManagementReadModel
    public let statusMessage: String?
    public let onAction: (ProManagementAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: ProManagementReadModel,
        statusMessage: String? = nil,
        onAction: @escaping (ProManagementAction) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var teamID: UUID? { UUID(uuidString: model.team.stableID) }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette) {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header
                    if let statusMessage {
                        Text(statusMessage)
                            .foregroundStyle(palette.stateWarning.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("Offers and counters are retained until accepted, rejected, withdrawn, or expired. Cap previews use the current team ledger.")
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    activeNegotiations
                    startNegotiations
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .accessibilitySortPriority(100)
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    titleBlock
                    closeButton
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer()
                    closeButton
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("CONTRACT NEGOTIATION")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.proIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("Season \(model.seasonLabel) · cap remaining \(model.cap.remainingCap)")
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private var activeNegotiations: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("OPEN & RECENT OFFERS · \(model.negotiations.count)")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.proIdentity.color)
            if model.negotiations.isEmpty {
                CoachWorldSystemState(
                    .empty("No contract offers are on file."),
                    palette: palette
                )
            } else {
                ForEach(model.negotiations) { negotiation in
                    NegotiationCard(
                        negotiation: negotiation,
                        palette: palette,
                        onAction: onAction
                    )
                }
            }
        }
    }

    private var startNegotiations: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("ROSTER CONTRACTS")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.proIdentity.color)
            ForEach(model.activeRoster.filter { player in
                player.contract != nil
                    && !model.negotiations.contains {
                        $0.playerID == player.id && $0.status.isOpen
                    }
            }, id: \.id) { player in
                if let contract = player.contract, let teamID {
                    Button {
                        onAction(.beginNegotiation(
                            playerID: player.id,
                            teamID: teamID,
                            offer: contract,
                            deadline: model.calendar.advancedWeek().advancedWeek()
                        ))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                Text(player.name).font(CoachWorldTokens.TypeRole.body.weight(.bold))
                                Text("Current cap hit \(player.capHit)")
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                            }
                            Spacer()
                            Text("Start offer")
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        }
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                               alignment: .leading)
                        .coachWorldFloodlitPanel(
                            fill: palette.raised.color,
                            border: palette.contentQuiet.color
                                .opacity(CoachWorldTokens.Depth.panelBorderOpacity)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start contract offer for \(player.name)")
                }
            }
        }
    }
}

private struct NegotiationCard: View {
    let negotiation: ProManagementReadModel.NegotiationRow
    let palette: CoachWorldTokens.Palette
    let onAction: (ProManagementAction) -> Void

    @State private var years: Int
    @State private var baseSalary: Int
    @State private var signingBonus: Int

    init(
        negotiation: ProManagementReadModel.NegotiationRow,
        palette: CoachWorldTokens.Palette,
        onAction: @escaping (ProManagementAction) -> Void
    ) {
        self.negotiation = negotiation
        self.palette = palette
        self.onAction = onAction
        _years = State(initialValue: negotiation.currentOffer.years)
        _baseSalary = State(initialValue: negotiation.currentOffer.baseSalaryByYear.first ?? 0)
        _signingBonus = State(initialValue: negotiation.currentOffer.signingBonus)
    }

    private var counter: Contract {
        Contract(
            years: years,
            baseSalaryByYear: Array(repeating: max(0, baseSalary), count: max(1, years)),
            signingBonus: max(0, signingBonus)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            HStack {
                Text(negotiation.playerName).font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Spacer()
                Text(negotiation.status.rawValue.uppercased())
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            }
            Text("Offer \(negotiation.offerCount) · \(negotiation.currentOffer.totalValue) total · deadline \(negotiation.deadline.season)-\(negotiation.deadline.week)")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
            if negotiation.status.isOpen {
                Stepper("Years: \(years)", value: $years, in: 1...ProRules.contractYearsRange.upperBound)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                TextField("Annual base salary", value: $baseSalary, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                TextField("Signing bonus", value: $signingBonus, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                actionButton("Counter", role: .secondary) {
                    onAction(.counterNegotiation(negotiationID: negotiation.id, offer: counter))
                }
                actionButton("Accept", role: .primary) {
                    onAction(.acceptNegotiation(negotiationID: negotiation.id))
                }
                actionButton("Reject", role: .secondary) {
                    onAction(.rejectNegotiation(negotiationID: negotiation.id))
                }
                actionButton("Withdraw", role: .secondary) {
                    onAction(.withdrawNegotiation(negotiationID: negotiation.id))
                }
            }
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
        )
        .accessibilityElement(children: .contain)
    }

    private func actionButton(
        _ title: String,
        role: CoachWorldActionRole,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .buttonStyle(CoachWorldActionButtonStyle(role: role, palette: palette))
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
    }
}
