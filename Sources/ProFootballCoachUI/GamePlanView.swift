import SwiftUI
import FootballSimCore

public struct GamePlanView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: GamePlanReadModel
    public let title: String
    public let statusMessage: String?
    public let onSelect: (TacticalPlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String

    public init(
        model: GamePlanReadModel,
        title: String = "GAME PLAN",
        statusMessage: String? = nil,
        onSelect: @escaping (TacticalPlan) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.statusMessage = statusMessage
        self.onSelect = onSelect
        self.onClose = onClose
        _selectedID = State(initialValue: model.options.first {
            $0.plan == model.currentPlan
        }?.id ?? model.options.first?.id ?? "")
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                dialGrid
                installs
                commitBar
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(
                model.opponent.map { "\(title) \u{00B7} \($0.name)" } ?? title,
                palette: palette
            )
            .accessibilityIdentifier("weekly-command-screen-11")
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3("You decide", palette: palette, tint: palette.actionPrimary.color)
        }
    }

    /// The reference draws the plan as a grid of dials, one per dimension.
    ///
    /// It shows four (tempo, aggression, personnel, coverage). This engine's `TacticalPlan` holds
    /// **three** — tempo, pressure and run/pass bias — and there is no coverage dimension anywhere
    /// in it. So three dials are drawn and no fourth is invented: a dial for a setting the
    /// simulation does not have would be a control that changes nothing.
    private var dialGrid: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            if let plan = model.currentPlan ?? selectedOption?.plan {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: CoachWorldTokens.Gap.smPlus),
                        GridItem(.flexible(), spacing: CoachWorldTokens.Gap.smPlus),
                    ],
                    spacing: CoachWorldTokens.Gap.smPlus
                ) {
                    dial("Tempo", value: label(plan.tempo))
                        .accessibilityIdentifier("weekly-command-dominant")
                    dial("Aggression", value: label(plan.pressure))
                    dial("Balance", value: label(plan.runPassBias))
                }
            } else {
                Text("No tactical plan is available for this week.")
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.contentSecondary.color)
                    .accessibilityIdentifier("weekly-command-dominant")
            }
        }
    }

    private func dial(_ slot: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            FloodlitLabel3(slot, palette: palette)
            Text(value.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.title, weight: .heavy)
                .lineLimit(1)
                .minimumScaleFactor(GamePlanMetric.dialScaleFloor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slot), \(value)")
    }

    private func label(_ tempo: TacticalTempo) -> String {
        switch tempo {
        case .deliberate: "Grind it"
        case .balanced: "Balanced"
        case .hurry: "Push the pace"
        }
    }

    private func label(_ pressure: TacticalPressure) -> String {
        switch pressure {
        case .contain: "Contain"
        case .balanced: "Balanced"
        case .attack: "Aggressive"
        }
    }

    private func label(_ bias: TacticalRunPassBias) -> String {
        switch bias {
        case .runHeavy: "Run heavy"
        case .balanced: "Balanced"
        case .passHeavy: "Pass heavy"
        }
    }

    /// The available installs, one row each. The read model carries consequences but no clock or
    /// resource cost, so the heading names the choice without promising a missing figure.
    private var installs: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Choose the install", palette: palette)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: CoachWorldTokens.Gap.xs) {
                    ForEach(model.options) { option in
                        installRow(option)
                    }
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.xs) {
                    ForEach(model.options) { option in
                        installRow(option)
                            .frame(minWidth: .zero, maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func installRow(_ option: GamePlanReadModel.Option) -> some View {
        FloodlitRow(
            isSelected: selectedID == option.id,
            palette: palette,
            action: {
                selectedID = option.id
            }
        ) {
            Text(option.title.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                .lineLimit(1)
                .minimumScaleFactor(GamePlanMetric.optionScaleFloor)
        }
        .accessibilityLabel("\(option.title). \(option.consequence)")
    }

    /// One committing action, bottom-right in the thumb arc.
    private var commitBar: some View {
        FloodlitCard(palette: palette, depth: .glass) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                    selectedConsequence
                    commitAction
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.md) {
                    selectedConsequence
                    Spacer(minLength: .zero)
                    commitAction
                }
            }
        }
    }

    private var selectedConsequence: some View {
        Text(selectedOption?.consequence ?? "Choose a tactical plan to commit.")
            .font(CoachWorldTokens.TypeRole.caption)
            .foregroundStyle(palette.contentSecondary.color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var commitAction: some View {
        FloodlitCommittingAction(
            selectedOption.map { "Set \($0.title)" } ?? "Set the install",
            action: {
                guard let selectedOption else { return }
                onSelect(selectedOption.plan)
                onClose()
            }
        )
        .disabled(selectedOption == nil)
    }

    private var selectedOption: GamePlanReadModel.Option? {
        model.options.first { $0.id == selectedID } ?? model.options.first
    }
}

private enum GamePlanMetric {
    static let dialScaleFloor: CGFloat = 0.6
    static let optionScaleFloor: CGFloat = 0.7
}
