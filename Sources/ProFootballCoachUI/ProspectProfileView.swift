import SwiftUI

/// A focused prospect dossier backed by the same recruiting-board projection.
/// The selected ID is route-scoped; the board remains the authority for every action.
public struct ProspectProfileView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RecruitingBoardReadModel
    public let prospectID: String?
    public let statusMessage: String?
    public let onAction: (String, CoachWorldIntentID) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: RecruitingBoardReadModel,
        prospectID: String? = nil,
        statusMessage: String? = nil,
        onAction: @escaping (String, CoachWorldIntentID) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.prospectID = prospectID
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var prospect: RecruitingBoardReadModel.Prospect? {
        let all = model.prospects + model.discovery
        if let prospectID, let match = all.first(where: { $0.stableID == prospectID }) {
            return match
        }
        return all.first
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let prospect {
                    dossier(prospect)
                } else {
                    CoachWorldSystemState(
                        .empty(
                            "No prospect selected. Return to the recruiting board to "
                                + "choose a prospect."
                        ),
                        palette: palette
                    )
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    /// The reference's three columns: who the prospect is and the system's verdict on the left,
    /// three headline facts in the middle, the relationship log on the right. What this build adds
    /// beneath them is what the reference puts in its own info bar -- the available actions -- as
    /// rows rather than two fixed buttons, because the board's choice list is not always two long
    /// and never the same two.
    private func dossier(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            if dynamicTypeSize.isAccessibilitySize {
                identityBlock(prospect)
                headlineFacts(prospect)
                relationshipLog(prospect)
            } else {
                HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                    identityBlock(prospect)
                        .frame(width: ProspectMetric.identityColumn)
                    headlineFacts(prospect)
                        .frame(width: ProspectMetric.factColumn)
                    relationshipLog(prospect)
                }
            }
            actionList(prospect)
        }
    }

    private func identityBlock(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                FloodlitLabel3(rankLabel(prospect), palette: palette, tint: palette.actionPrimary.color)
                Text(prospect.person.name.uppercased())
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.figure, weight: .bold)
                    .lineLimit(ProspectMetric.nameLines)
                    .minimumScaleFactor(ProspectMetric.nameScaleFloor)
                Text("\(prospect.position) \u{00B7} \(prospect.hometown)")
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(rankLabel(prospect)), \(prospect.person.name), \(prospect.position), "
                    + "\(prospect.hometown), \(prospect.status)"
            )
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                FloodlitLabel3("System evaluation", palette: palette)
                Text(prospect.evaluation.verdict)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .fixedSize(horizontal: false, vertical: true)
                if !prospect.evaluation.citedOutliers.isEmpty {
                    Text(prospect.evaluation.citedOutliers.prefix(3).joined(separator: " \u{00B7} "))
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rankLabel(_ prospect: RecruitingBoardReadModel.Prospect) -> String {
        prospect.boardRank == 0
            ? "Discovery \u{00B7} \(prospect.status)"
            : "Board #\(prospect.boardRank) \u{00B7} \(prospect.status)"
    }

    /// Scheme fit, uncertainty, interest -- the reference's three headline figures, each at the
    /// same weight because none of the three outranks the others.
    private func headlineFacts(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            headlineFact("Scheme fit", prospect.evaluation.schemeFit)
            headlineFact("Uncertainty", prospect.evaluation.uncertainty)
            headlineFact("Interest", prospect.interest)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headlineFact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
            FloodlitLabel3(label, palette: palette)
            Text(value.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.title, weight: .bold)
                .lineLimit(1)
                .minimumScaleFactor(ProspectMetric.factScaleFloor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private func relationshipLog(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Relationship log", palette: palette)
            if prospect.relationshipHistory.isEmpty {
                Text("No contact recorded.")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
            } else {
                ForEach(prospect.relationshipHistory, id: \.stableID) { event in
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                        Text(event.dateLabel)
                            .coachWorldFigure(CoachWorldTokens.DisplaySize.flag)
                            .foregroundStyle(palette.contentQuiet.color)
                        Text(event.summary)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(event.effect)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, CoachWorldTokens.Gap.hair)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// What acting on this prospect costs. The reference draws exactly two fixed buttons --
    /// ghost "Shortlist", primary "Offer a scholarship" -- but the board's own choice list is not
    /// always two long and is never the same two, so every recorded choice becomes a row instead.
    /// A picked pair would silently hide whichever action fell outside it.
    @ViewBuilder
    private func actionList(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        if !prospect.choices.isEmpty {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
                FloodlitLabel3("What you can do", palette: palette)
                ForEach(prospect.choices, id: \.intentID) { choice in
                    FloodlitRow(
                        palette: palette,
                        action: choice.isAvailable
                            ? { onAction(prospect.stableID, choice.intentID) }
                            : nil
                    ) {
                        HStack(spacing: CoachWorldTokens.Gap.md) {
                            Text(choice.title.uppercased())
                                .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                                .foregroundStyle(
                                    choice.isAvailable
                                        ? palette.contentPrimary.color
                                        : palette.contentQuiet.color
                                )
                                .lineLimit(1)
                                .frame(width: ProspectMetric.actionColumn, alignment: .leading)
                            if choice.isAvailable {
                                FloodlitCostLine(
                                    cost: choice.cost,
                                    consequence: choice.consequence.isEmpty
                                        ? nil : choice.consequence,
                                    palette: palette
                                )
                            } else {
                                Text(choice.unavailableReason ?? "Not available.")
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.stateWarning.color)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: CoachWorldTokens.Gap.xs)
                        }
                    }
                    .accessibilityLabel(
                        "\(choice.title) for \(prospect.person.name). "
                            + (choice.isAvailable
                                ? "\(choice.cost). \(choice.consequence)"
                                : (choice.unavailableReason ?? "Not available."))
                    )
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(footerNote)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Back to recruiting board", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }

    private var footerNote: String {
        guard let prospect else { return "Choose a prospect from the board." }
        return prospect.choices.isEmpty
            ? "No action is currently available for this prospect."
            : "Every action here comes off this week's budget."
    }
}

private enum ProspectMetric {
    static let identityColumn: CGFloat = 300
    static let factColumn: CGFloat = 180
    static let nameLines = 2
    static let nameScaleFloor: CGFloat = 0.6
    static let factScaleFloor: CGFloat = 0.7
    static let actionColumn: CGFloat = 150
}
