import SwiftUI
import FootballSimCore

public struct PracticePlanView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: PracticePlanReadModel
    public let statusMessage: String?
    public let onSelect: (TacticalPracticePlan) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedID: String

    public init(
        model: PracticePlanReadModel,
        statusMessage: String? = nil,
        onSelect: @escaping (TacticalPracticePlan) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
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
                HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
                    FloodlitLabel3("Practice plan \u{00B7} \(model.weekLabel)", palette: palette)
                        .accessibilityIdentifier("weekly-command-screen-12")
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitLabel3("You decide", palette: palette, tint: palette.actionPrimary.color)
                }
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                allocator
                options
                commitBar
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
    }

    /// The week's minutes as an allocation, which is what the reference's allocator shows: four
    /// sessions sharing one stated whole.
    ///
    /// A share bar is legitimate here precisely because each session is a proportion of
    /// `TacticalPracticePlan.weeklyMinutes` — a stated total, not an open-ended count.
    @ViewBuilder
    private var allocator: some View {
        if let plan = allocatedPlan {
            FloodlitCard(palette: palette, depth: .deep) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                    HStack(spacing: CoachWorldTokens.Gap.xs) {
                        FloodlitLabel3(
                            model.currentPlan == nil ? "Option preview"
                                                     : "This week",
                            palette: palette,
                            tint: model.currentPlan == nil ? palette.stateWarning.color : nil
                        )
                        .accessibilityIdentifier("weekly-command-dominant")
                        Spacer(minLength: .zero)
                        Text("\(TacticalPracticePlan.weeklyMinutes)\u{2032} allocated")
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    session("Install", minutes: plan.installMinutes)
                    session("Conditioning", minutes: plan.conditioningMinutes)
                    session("Recovery", minutes: plan.recoveryMinutes)
                    session(
                        plan.positionFocus.map { "Focus \u{00B7} \(label($0))" }
                            ?? "Position focus",
                        minutes: plan.positionFocusMinutes
                    )
                }
            }
        } else {
            FloodlitCard(palette: palette, depth: .deep) {
                Text("No practice allocation is available for this week.")
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.contentSecondary.color)
                    .accessibilityIdentifier("weekly-command-dominant")
            }
        }
    }


    /// The allocation the bars draw. Before the week is committed there is no stored plan, and the
    /// reference's allocator is the whole point of the screen -- so it draws what the selected
    /// option *would* allocate, labelled as not yet set rather than presented as the week.
    private var allocatedPlan: TacticalPracticePlan? {
        if let current = model.currentPlan { return current }
        let selected = model.options.first { $0.id == selectedID } ?? model.options.first
        return selected?.plan
    }

    private func session(_ name: String, minutes: Int) -> some View {
        FloodlitRow(palette: palette) {
            HStack(spacing: CoachWorldTokens.Gap.xs) {
                Text(name.uppercased())
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .lineLimit(1)
                    .frame(width: PracticeMetric.sessionLabel, alignment: .leading)
                FloodlitShareBar(
                    proportion: Double(minutes) / Double(TacticalPracticePlan.weeklyMinutes),
                    palette: palette
                )
                // Minutes take a prime, per the handoff's copy rules.
                Text("\(minutes)\u{2032}")
                    .font(
                        CoachWorldTokens.figure(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .frame(width: PracticeMetric.minutesColumn, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(minutes) minutes of \(TacticalPracticePlan.weeklyMinutes)")
    }

    private func label(_ group: PositionGroup) -> String {
        String(describing: group).replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Choose the week", palette: palette)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: CoachWorldTokens.Gap.xs) {
                    ForEach(model.options) { option in
                        optionRow(option)
                    }
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.xs) {
                    ForEach(model.options) { option in
                        optionRow(option)
                            .frame(minWidth: .zero, maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func optionRow(_ option: PracticePlanReadModel.Option) -> some View {
        FloodlitRow(
            isSelected: selectedID == option.id,
            palette: palette,
            action: {
                selectedID = option.id
            }
        ) {
            Text(option.title.uppercased())
                .font(
                    CoachWorldTokens.display(
                        CoachWorldTokens.DisplaySize.row, weight: .bold
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(PracticeMetric.optionScaleFloor)
        }
        .accessibilityLabel("\(option.title). \(option.consequence)")
    }

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
        Text(selectedOption?.consequence ?? "Choose a practice allocation to commit.")
            .font(CoachWorldTokens.TypeRole.caption)
            .foregroundStyle(palette.contentSecondary.color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var commitAction: some View {
        FloodlitCommittingAction(
            selectedOption.map { "Set \($0.title)" } ?? "Set the week",
            action: {
                guard let selectedOption else { return }
                onSelect(selectedOption.plan)
                onClose()
            }
        )
        .disabled(selectedOption == nil)
    }

    private var selectedOption: PracticePlanReadModel.Option? {
        model.options.first { $0.id == selectedID } ?? model.options.first
    }
}

private enum PracticeMetric {
    static let sessionLabel: CGFloat = 104
    static let minutesColumn: CGFloat = 38
    static let optionScaleFloor: CGFloat = 0.7
}
