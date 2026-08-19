import SwiftUI
import FootballSimCore

public struct CollegeOffseasonView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: CollegeOffseasonReadModel
    public let title: String
    public let statusMessage: String?
    public let onCommit: (CoachWorldIntentID) -> Void
    public let onContinue: () -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pendingDecision: PendingDecision?

    private struct PendingDecision: Identifiable {
        let id: String
        let intentID: CoachWorldIntentID
        let title: String
        let decisionTitle: String
        let cost: String
        let consequence: String
    }

    public init(
        model: CollegeOffseasonReadModel,
        title: String = "COLLEGE OFFSEASON",
        statusMessage: String? = nil,
        onCommit: @escaping (CoachWorldIntentID) -> Void,
        onContinue: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onContinue = onContinue
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .alert(item: $pendingDecision) { decision in
            Alert(
                title: Text("Choose \(decision.title) for \(decision.decisionTitle)?"),
                message: Text("\(decision.cost). \(decision.consequence)"),
                primaryButton: .default(
                    Text("Choose \(decision.title) for \(decision.decisionTitle) · \(decision.consequence)")
                ) {
                    onCommit(decision.intentID)
                },
                secondaryButton: .cancel()
            )
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
                    ledgerColumn
                    decisionColumn
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        ledgerColumn
                            .frame(width: OffseasonMetric.ledgerColumn)
                        decisionColumn
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(
                "\(title) \u{00B7} season \(model.recruitingSeason)", palette: palette
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(phaseLabel, palette: palette, tint: palette.actionPrimary.color)
        }
    }

    /// What the cycle is holding: capacity, budget and how much of each is spent. Every figure has
    /// a stated whole, which is what makes a share bar honest here.
    private var ledgerColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Where the cycle stands", palette: palette)
            allocation(
                "Board",
                spent: model.boardCount,
                of: CollegeRules.recruitingBoardLimit,
                figure: "\(model.boardCount)/\(CollegeRules.recruitingBoardLimit)"
            )
            allocation(
                "Scholarships",
                spent: model.scholarshipCount,
                of: CollegeRules.scholarshipLimit,
                figure: "\(model.scholarshipCount)/\(CollegeRules.scholarshipLimit)"
            )
            allocation(
                "NIL",
                spent: model.nilCommitted,
                of: max(model.nilBudget, 1),
                figure: currency(model.nilBudget - model.nilCommitted) + " left"
            )
            fact("Contact points", "\(model.contactPointsRemaining) left")
            fact("Portal", portalLabel)
            fact(
                "In the portal",
                model.portalEntryCount == 1
                    ? "1 player" : "\(model.portalEntryCount) players"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func allocation(_ label: String, spent: Int, of whole: Int, figure: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            HStack(spacing: CoachWorldTokens.Gap.xs) {
                FloodlitLabel3(label, palette: palette)
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                Text(figure)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.actionSmall, weight: .semibold)
                    .lineLimit(1)
            }
            FloodlitShareBar(
                proportion: whole > 0 ? Double(spent) / Double(whole) : 0,
                palette: palette
            )
        }
        .frame(minHeight: OffseasonMetric.allocationHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(figure)")
    }

    private func fact(_ key: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(key, palette: palette)
                .frame(width: OffseasonMetric.factKey, alignment: .leading)
            Text(value)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: OffseasonMetric.factHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(OffseasonMetric.seamAlpha))
                .frame(height: CoachWorldTokens.Shape.hairline)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key), \(value)")
    }

    /// What the cycle is waiting on. Each choice carries its own cost and the interface never says
    /// which to take.
    @ViewBuilder
    private var decisionColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("What is waiting on you", palette: palette)
            if model.decisions.isEmpty && model.delegatedDecisionCount == 0 {
                emptyState
            } else if model.decisions.isEmpty {
                delegatedState
            } else {
                ForEach(model.decisions, id: \.stableID) { decision in
                    decisionCard(decision)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func decisionCard(_ decision: CoachingHQReadModel.Decision) -> some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
                    Text(decision.title)
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.panel, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitFlag(
                        "Due \(decision.deadline)",
                        tint: palette.stateWarning.color,
                        palette: palette
                    )
                }
                ForEach(decision.choices, id: \.intentID) { choice in
                    let consequence = choice.isAvailable
                        ? (choice.consequence.isEmpty ? "record the choice" : choice.consequence)
                        : (choice.unavailableReason ?? choice.consequence)
                    let encodedIntentID = CoachWorldIntentID(
                        rawValue: "\(decision.stableID)|\(choice.intentID.rawValue)"
                    )
                    FloodlitRow(
                        palette: palette,
                        action: choice.isAvailable
                            ? {
                                pendingDecision = PendingDecision(
                                    id: encodedIntentID.rawValue,
                                    intentID: encodedIntentID,
                                    title: choice.title,
                                    decisionTitle: decision.title,
                                    cost: choice.cost,
                                    consequence: consequence
                                )
                            }
                            : nil
                    ) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                            Text(choice.title.uppercased())
                                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                                .lineLimit(1)
                            FloodlitCostLine(
                                cost: choice.cost,
                                consequence: consequence.isEmpty ? nil : consequence,
                                palette: palette
                            )
                        }
                    }
                    .accessibilityLabel(
                        "\(choice.title) for \(decision.title)"
                            + (choice.isAvailable ? "" : ". Unavailable")
                    )
                    .accessibilityHint(
                        consequence.isEmpty ? choice.cost : consequence
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        CoachWorldSystemState(
            .empty(
                "No college-cycle decision is waiting. The portal and recruiting ledgers "
                    + "are current for this boundary."
            ),
            palette: palette
        )
    }

    /// The first production consumer of `04` section 7's delegated state: this screen already
    /// described exactly that condition in its own words, so it adopts the shared component the
    /// canon names rather than keeping a second hand-rolled spelling of it.
    private var delegatedState: some View {
        CoachWorldSystemState(
            .delegated(
                "Staff decision in progress. \(model.delegatedDecisionCount) delegated "
                    + "decision(s) remain with the assigned staff owner."
            ),
            palette: palette
        )
    }

    private var footer: some View {
        let canAdvance = model.decisions.isEmpty && model.delegatedDecisionCount == 0
        return HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(footerNote)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction(
                "Advance week",
                isEnabled: canAdvance,
                action: onContinue
            )
            .accessibilityHint(
                canAdvance
                    ? ""
                    : (model.delegatedDecisionCount > 0 && model.decisions.isEmpty
                        ? "Wait for the staff decision to finish before advancing."
                        : "Answer the open decisions before the cycle moves on.")
            )
        }
        .floodlitFooterStrip(palette: palette)
    }

    private var footerNote: String {
        if !model.decisions.isEmpty {
            let count = model.decisions.count
            return count == 1
                ? "One decision is still open."
                : "\(count) decisions are still open."
        }
        if model.delegatedDecisionCount > 0 {
            return "The staff is working. Nothing is waiting on you."
        }
        return "The cycle is current."
    }

    private var phaseLabel: String {
        switch model.cyclePhase {
        case .active: return "Recruiting active"
        case .signing: return "Signing period"
        case .closed: return "Cycle closed"
        }
    }

    private var portalLabel: String {
        switch model.portalPhase {
        case .closed: return "Closed"
        case .postseasonOpen: return "Postseason window"
        case .awaitingSpring: return "Awaiting spring"
        case .springOpen: return "Spring window"
        }
    }

    private func currency(_ value: Int) -> String {
        value < 0 ? "-$\(abs(value))" : "$\(value)"
    }
}

private enum OffseasonMetric {
    static let ledgerColumn: CGFloat = 300
    static let factKey: CGFloat = 96
    static let factHeight: CGFloat = 21
    static let allocationHeight: CGFloat = 34
    static let seamAlpha = 0.05
}
