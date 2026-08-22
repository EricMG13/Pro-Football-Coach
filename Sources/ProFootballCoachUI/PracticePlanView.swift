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
                            selectedOption?.title ?? "Current plan",
                            palette: palette
                        )
                        .accessibilityIdentifier("weekly-command-dominant")
                        Spacer(minLength: .zero)
                        Text("\(TacticalPracticePlan.weeklyMinutes)\u{2032} allocated")
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    sessions(of: plan)
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


    /// The allocation the bars draw follows the local option selection, which is also the payload
    /// the commit action sends. A stored plan is only the fallback when no option can be selected.
    private var allocatedPlan: TacticalPracticePlan? {
        selectedOption?.plan ?? model.currentPlan
    }

    /// The four sessions sharing the week's stated total.
    ///
    /// The reference draws them as columns, and that is also what keeps the committing action
    /// inside the initial viewport: stacked, the four rows cost about 155 points of a 291-point
    /// scroll viewport and push the commit off the bottom edge, which `04` section 7 allows only at
    /// AX5. So AX5 keeps the stack -- four columns cannot hold their labels at accessibility sizes,
    /// and AX5 is exactly where scrolling is permitted.
    @ViewBuilder
    private func sessions(of plan: TacticalPracticePlan) -> some View {
        let focus = plan.positionFocus.map { "Focus \u{00B7} \(label($0))" } ?? "Position focus"
        if dynamicTypeSize.isAccessibilitySize {
            session("Install", minutes: plan.installMinutes)
            session("Conditioning", minutes: plan.conditioningMinutes)
            session("Recovery", minutes: plan.recoveryMinutes)
            session(focus, minutes: plan.positionFocusMinutes)
        } else {
            HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xs) {
                sessionColumn("Install", minutes: plan.installMinutes)
                sessionColumn("Conditioning", minutes: plan.conditioningMinutes)
                sessionColumn("Recovery", minutes: plan.recoveryMinutes)
                sessionColumn(focus, minutes: plan.positionFocusMinutes)
            }
        }
    }

    private func sessionColumn(_ name: String, minutes: Int) -> some View {
        FloodlitRow(palette: palette) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                // Deliberately no `minimumScaleFactor`. This is 12-point type and
                // `TypeRole.authoredFloor` is 12, so any shrink at all drops authored text under
                // the floor -- a long focus name such as "FOCUS - OFFENSIVE LINE" would render
                // near 9 points. It truncates instead, and the accessibility label below still
                // carries the whole name.
                Text(name.uppercased())
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .lineLimit(1)
                FloodlitShareBar(
                    proportion: Double(minutes) / Double(TacticalPracticePlan.weeklyMinutes),
                    palette: palette
                )
                Text("\(minutes)\u{2032}")
                    .font(
                        CoachWorldTokens.figure(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(minutes) minutes of \(TacticalPracticePlan.weeklyMinutes)")
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
