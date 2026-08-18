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
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header
                    if let statusMessage {
                        Text(statusMessage)
                            .font(CoachWorldTokens.TypeRole.callout)
                            .foregroundStyle(palette.stateWarning.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    summary
                    if model.decisions.isEmpty && model.delegatedDecisionCount == 0 {
                        emptyState
                    } else if model.decisions.isEmpty {
                        delegatedState
                    } else {
                        decisions
                    }
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
                    controls
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer(minLength: CoachWorldTokens.Space.sm)
                    controls
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.programme.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text("Season \(model.recruitingSeason) · \(phaseLabel)")
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var controls: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            if model.decisions.isEmpty && model.delegatedDecisionCount == 0 {
                Button("Continue", action: onContinue)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .live, palette: palette))
            }
            Button("Done", action: onClose)
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private var summary: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: CoachWorldTokens.Space.xs)],
            alignment: .leading,
            spacing: CoachWorldTokens.Space.xs
        ) {
            summaryCell("PORTAL", portalLabel)
            summaryCell("BOARD", "\(model.boardCount)/\(CollegeRules.recruitingBoardLimit)")
            summaryCell("SCHOLARSHIPS", "\(model.scholarshipCount)/\(CollegeRules.scholarshipLimit)")
            summaryCell("CONTACT POINTS", "\(model.contactPointsRemaining)")
            summaryCell("NIL REMAINING", currency(model.nilBudget - model.nilCommitted))
        }
        .accessibilitySortPriority(80)
    }

    private var decisions: some View {
        section("OPEN DECISIONS") {
            ForEach(model.decisions, id: \.stableID) { decision in
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(decision.title)
                            .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                        Spacer(minLength: CoachWorldTokens.Space.xs)
                        Text("DUE · \(decision.deadline.uppercased())")
                            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                            .foregroundStyle(palette.stateWarning.color)
                    }
                    ForEach(decision.choices, id: \.intentID) { choice in
                        Button {
                            onCommit(choice.intentID)
                        } label: {
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                Text(choice.title)
                                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                Text(choice.consequence.isEmpty ? choice.cost : choice.consequence)
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                                   alignment: .leading)
                        }
                        .buttonStyle(CoachWorldActionButtonStyle(role: .live, palette: palette))
                        .accessibilityLabel("\(choice.title) for \(decision.title)")
                        .accessibilityHint(choice.consequence.isEmpty ? choice.cost : choice.consequence)
                    }
                }
                .padding(CoachWorldTokens.Space.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .coachWorldFloodlitPanel(
                    fill: palette.raised.color,
                    border: palette.contentQuiet.color
                        .opacity(CoachWorldTokens.Depth.panelBorderOpacity)
                )
                .accessibilityElement(children: .contain)
            }
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

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            content()
        }
    }

    private func summaryCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label.capitalized), \(value)")
    }

    private var phaseLabel: String {
        switch model.cyclePhase {
        case .active: return "Recruiting active · \(portalLabel)"
        case .signing: return "Signing period · \(portalLabel)"
        case .closed: return "Cycle closed · \(portalLabel)"
        }
    }

    private var portalLabel: String {
        switch model.portalPhase {
        case .closed: return "Portal closed"
        case .postseasonOpen: return "Postseason portal"
        case .awaitingSpring: return "Awaiting spring portal"
        case .springOpen: return "Spring portal"
        }
    }

    private func currency(_ value: Int) -> String {
        value < 0 ? "-$\(abs(value))" : "$\(value)"
    }
}
