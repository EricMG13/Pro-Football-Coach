import SwiftUI

public struct ContactVisitPlannerView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RecruitingBoardReadModel
    public let statusMessage: String?
    public let onAction: (String, CoachWorldIntentID) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: RecruitingBoardReadModel, statusMessage: String? = nil,
                onAction: @escaping (String, CoachWorldIntentID) -> Void,
                onClose: @escaping () -> Void) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                budgetBar
                // The reference draws a seven-day visit-calendar grid here -- per-day contact
                // and visit slots with a note per day. RecruitingBoardReadModel has no per-day
                // schedule field to back one (the capacity it does hold is a weekly total, not a
                // day-by-day allocation), so the grid is not drawn rather than approximated.
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                FloodlitLabel3("Unbooked \u{00B7} costs come off the week", palette: palette)
                if bookable.isEmpty {
                    CoachWorldSystemState(
                        .empty(
                            "Nothing is bookable this week. The board records no contact, "
                                + "evaluation or visit the budget can still pay for."
                        ),
                        palette: palette
                    )
                } else {
                    ForEach(bookable, id: \.prospect.stableID) { entry in
                        prospectRow(entry.prospect, choices: entry.choices)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    /// What the week has left, across the top. The reference puts the budget above the list because
    /// every row below it spends from exactly these two figures.
    private var budgetBar: some View {
        HStack(spacing: CoachWorldTokens.Gap.xl) {
            budgetFigure(
                "Contact points", "\(model.capacity.weeklyHoursRemaining)"
            )
            budgetFigure(
                "Official visits", "\(model.capacity.officialVisitsRemaining)"
            )
            budgetFigure(
                "Scholarships", "\(model.capacity.scholarshipSlotsRemaining)"
            )
            Spacer(minLength: CoachWorldTokens.Gap.xs)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: PlannerMetric.budgetHeight)
        .background(
            CoachWorldCutCorner.row.fill(palette.work.color.opacity(PlannerMetric.budgetFill))
        )
    }

    private func budgetFigure(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            FloodlitLabel3(label, palette: palette)
            Text(value)
                .coachWorldFigure(CoachWorldTokens.DisplaySize.lead, weight: .semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value) left")
    }

    /// The three actions this surface books. Filtering by intent rather than by title so a renamed
    /// action does not silently drop off the planner.
    private static let bookableIntents: Set<String> = ["contact", "evaluate", "scheduleVisit"]

    private var bookable: [(prospect: RecruitingBoardReadModel.Prospect,
                            choices: [CoachWorldActionChoice])] {
        model.prospects.compactMap { prospect in
            let choices = prospect.choices.filter {
                Self.bookableIntents.contains($0.intentID.rawValue)
            }
            return choices.isEmpty ? nil : (prospect, choices)
        }
    }

    private func prospectRow(
        _ prospect: RecruitingBoardReadModel.Prospect,
        choices: [CoachWorldActionChoice]
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            // At AX5 sizes the fixed-width name column would either clip the name or force the
            // row to overflow the stage; stacking the name over its context line lets both wrap.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(prospect.person.name.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                        .fixedSize(horizontal: false, vertical: true)
                    FloodlitLabel3(
                        "\(prospect.position) \u{00B7} \(prospect.status) \u{00B7} "
                            + "\(prospect.interest) interest",
                        palette: palette
                    )
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.md) {
                    Text(prospect.person.name.uppercased())
                        .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                        .lineLimit(1)
                        .frame(width: PlannerMetric.nameColumn, alignment: .leading)
                    FloodlitLabel3(
                        "\(prospect.position) \u{00B7} \(prospect.status) \u{00B7} "
                            + "\(prospect.interest) interest",
                        palette: palette
                    )
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                }
            }
            ForEach(choices, id: \.intentID) { choice in
                actionRow(prospect, choice)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    /// One bookable action, with what it costs. An unavailable action states its refusal rather
    /// than disappearing -- a coach needs to know the visit is gone, not wonder where it went.
    private func actionRow(
        _ prospect: RecruitingBoardReadModel.Prospect,
        _ choice: CoachWorldActionChoice
    ) -> some View {
        FloodlitRow(
            palette: palette,
            action: choice.isAvailable
                ? { onAction(prospect.stableID, choice.intentID) }
                : nil
        ) {
            let title = Text(choice.title.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                .foregroundStyle(
                    choice.isAvailable
                        ? palette.contentPrimary.color
                        : palette.contentQuiet.color
                )
            let costOrReason: some View = Group {
                if choice.isAvailable {
                    FloodlitCostLine(
                        cost: choice.cost,
                        consequence: choice.consequence.isEmpty ? nil : choice.consequence,
                        palette: palette
                    )
                } else {
                    Text(choice.unavailableReason ?? "Not available this week.")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // Same reflow as the row above: a fixed-width action-title column clips at AX5.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    title.fixedSize(horizontal: false, vertical: true)
                    costOrReason
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.md) {
                    title
                        .lineLimit(1)
                        .frame(width: PlannerMetric.actionColumn, alignment: .leading)
                    costOrReason
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                }
            }
        }
        .accessibilityLabel(
            "\(choice.title) for \(prospect.person.name). "
                + (choice.isAvailable
                    ? "\(choice.cost). \(choice.consequence)"
                    : (choice.unavailableReason ?? "Not available this week."))
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Every booking spends from the week. The planner never picks for you.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Back to recruiting board", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }
}

private enum PlannerMetric {
    static let nameColumn: CGFloat = 150
    static let actionColumn: CGFloat = 132
    static let budgetHeight: CGFloat = 52
    static let budgetFill = 0.5
}
