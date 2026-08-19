import SwiftUI
import FootballSimCore

/// The persistent offer/counter surface. Every mutation is a `ProManagementAction`; this view
/// never edits a player or cap ledger directly.
public struct ContractNegotiationView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


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
                Text(
                    "Offers and counters are retained until accepted, rejected, withdrawn, "
                        + "or expired. Cap previews use the current team ledger."
                )
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentQuiet.color)
                .fixedSize(horizontal: false, vertical: true)
                activeNegotiations
                startNegotiations
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("Contract negotiation \u{00B7} \(model.seasonLabel)", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(
                "\(currency(model.cap.remainingCap)) left",
                palette: palette,
                tint: model.cap.remainingCap < 0
                    ? palette.stateWarning.color
                    : palette.actionPrimary.color
            )
        }
    }

    private var activeNegotiations: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("Open and recent offers", palette: palette)
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                FloodlitLabel3(
                    model.negotiations.count == 1
                        ? "1 offer" : "\(model.negotiations.count) offers",
                    palette: palette
                )
            }
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

    /// Contracted players not already in an open negotiation: a place to start one. `04` section
    /// 4.4 -- the interface never says which player to approach -- so every eligible name is a row,
    /// not a shortlist.
    private var startNegotiations: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Start a negotiation", palette: palette)
            ForEach(startable, id: \.id) { player in
                startRow(player)
            }
        }
    }

    private var startable: [ProManagementReadModel.PlayerRow] {
        model.activeRoster.filter { player in
            player.contract != nil
                && !model.negotiations.contains { $0.playerID == player.id && $0.status.isOpen }
        }
    }

    @ViewBuilder
    private func startRow(_ player: ProManagementReadModel.PlayerRow) -> some View {
        if let contract = player.contract, let teamID {
            FloodlitRow(
                palette: palette,
                action: {
                    onAction(.beginNegotiation(
                        playerID: player.id,
                        teamID: teamID,
                        offer: contract,
                        deadline: model.calendar.advancedWeek().advancedWeek()
                    ))
                }
            ) {
                // At AX5, the name, the cap figure and "Start offer" crammed into one row would
                // either clip the name or force the row wider than the stage. Stacking the cap
                // figure and the offer label under the name keeps every piece legible.
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                        Text(player.name.uppercased())
                            .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: CoachWorldTokens.Gap.md) {
                            Text("\(currency(player.capHit)) now")
                                .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                                .foregroundStyle(palette.contentQuiet.color)
                            FloodlitLabel3(
                                "Start offer", palette: palette, tint: palette.actionPrimary.color
                            )
                        }
                    }
                } else {
                    HStack(spacing: CoachWorldTokens.Gap.md) {
                        Text(player.name.uppercased())
                            .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                            .lineLimit(1)
                        Spacer(minLength: CoachWorldTokens.Gap.xs)
                        Text("\(currency(player.capHit)) now")
                            .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                            .foregroundStyle(palette.contentQuiet.color)
                        FloodlitLabel3(
                            "Start offer", palette: palette, tint: palette.actionPrimary.color
                        )
                    }
                }
            }
            .accessibilityLabel(
                "Start an offer for \(player.name), current cap hit \(currency(player.capHit))"
            )
        }
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Every offer here is retained. Nothing is committed until you accept it.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }

    private func currency(_ value: Int) -> String {
        value < 0 ? "-$\(abs(value))" : "$\(value)"
    }
}

private struct NegotiationCard: View {
    let negotiation: ProManagementReadModel.NegotiationRow
    let palette: CoachWorldTokens.Palette
    let onAction: (ProManagementAction) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
                    Text(negotiation.playerName.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.panel, weight: .bold)
                        .lineLimit(1)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitFlag(
                        negotiation.status.rawValue,
                        tint: negotiation.status.isOpen
                            ? palette.actionPrimary.color
                            : palette.contentQuiet.color,
                        palette: palette
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(negotiation.playerName), \(negotiation.status.rawValue)"
                )
                FloodlitCostLine(
                    cost: "Offer \(negotiation.offerCount)",
                    exposure: "$\(negotiation.currentOffer.totalValue) total",
                    consequence: "Deadline \(negotiation.deadline.season)-\(negotiation.deadline.week)",
                    palette: palette
                )
                if negotiation.status.isOpen {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                        Stepper(
                            "Years: \(years)",
                            value: $years, in: 1...ProRules.contractYearsRange.upperBound
                        )
                        .font(CoachWorldTokens.TypeRole.body)
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                        TextField("Annual base salary", value: $baseSalary, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                        TextField("Signing bonus", value: $signingBonus, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                    }
                    // Four buttons in one row is tight even at standard type; at AX5 it would
                    // overflow the card. Two rows keeps every label legible and every target
                    // its full 44pt regardless of scale.
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                            HStack(spacing: CoachWorldTokens.Gap.md) {
                                quietButton("Withdraw") {
                                    onAction(.withdrawNegotiation(negotiationID: negotiation.id))
                                }
                                quietButton("Reject") {
                                    onAction(.rejectNegotiation(negotiationID: negotiation.id))
                                }
                            }
                            HStack(spacing: CoachWorldTokens.Gap.md) {
                                quietButton("Counter") {
                                    onAction(.counterNegotiation(
                                        negotiationID: negotiation.id, offer: counter
                                    ))
                                }
                                acceptButton {
                                    onAction(.acceptNegotiation(negotiationID: negotiation.id))
                                }
                            }
                        }
                    } else {
                        HStack(spacing: CoachWorldTokens.Gap.md) {
                            quietButton("Withdraw") {
                                onAction(.withdrawNegotiation(negotiationID: negotiation.id))
                            }
                            quietButton("Reject") {
                                onAction(.rejectNegotiation(negotiationID: negotiation.id))
                            }
                            Spacer(minLength: CoachWorldTokens.Gap.xs)
                            quietButton("Counter") {
                                onAction(.counterNegotiation(
                                    negotiationID: negotiation.id, offer: counter
                                ))
                            }
                            // Not FloodlitCommittingAction, and not
                            // CoachWorldActionButtonStyle(.primary) either -- that role also
                            // fills with `actionPrimary.color`, the same gold, so it would
                            // collide with the footer's Done exactly like the gold button did.
                            // A positive but non-gold tone keeps Accept visually distinct from
                            // Withdraw/Reject/Counter without claiming the screen's one
                            // committing slot.
                            acceptButton {
                                onAction(.acceptNegotiation(negotiationID: negotiation.id))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    /// Withdraw, Reject and Counter: none of them commits the offer, so none takes the gold field
    /// `04` section 6.5 reserves for exactly one action per screen.
    private func quietButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
            .foregroundStyle(palette.contentQuiet.color)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func acceptButton(action: @escaping () -> Void) -> some View {
        Button("Accept", action: action)
            .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
            .foregroundStyle(palette.statePositive.color)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }
}
