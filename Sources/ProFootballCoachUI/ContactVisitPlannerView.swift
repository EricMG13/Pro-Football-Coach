import SwiftUI

public struct ContactVisitPlannerView: View {
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
        CoachWorldFloodlitStage(palette: palette) {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header
                    if let statusMessage { Text(statusMessage).foregroundStyle(palette.stateWarning.color) }
                    Text("Choose an existing recruiting action. Costs and refusal reasons come from the current board.")
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(model.prospects, id: \.stableID) { prospect in
                        prospectRow(prospect)
                    }
                    if model.prospects.isEmpty {
                        CoachWorldSystemState(
                            .empty("No board prospects have a contact or visit plan."),
                            palette: palette
                        )
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
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) { titleBlock; closeButton }
            } else {
                HStack(alignment: .top) { titleBlock; Spacer(); closeButton }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("CONTACT & VISIT PLANNER").font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name).font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("Contact points \(model.capacity.weeklyHoursRemaining) · Visits \(model.capacity.officialVisitsRemaining)")
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func prospectRow(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(prospect.person.name).font(CoachWorldTokens.TypeRole.headline.weight(.bold))
            Text("\(prospect.position) · \(prospect.status)")
                .foregroundStyle(palette.contentSecondary.color)
            ForEach(prospect.choices.filter { choice in
                choice.intentID.rawValue == "contact"
                    || choice.intentID.rawValue == "evaluate"
                    || choice.intentID.rawValue == "scheduleVisit"
            }, id: \.intentID) { choice in
                Button {
                    onAction(prospect.stableID, choice.intentID)
                } label: {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(choice.title).font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                        Text(choice.isAvailable ? "\(choice.cost) · \(choice.consequence)"
                             : (choice.unavailableReason ?? "Unavailable"))
                            .font(CoachWorldTokens.TypeRole.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                           alignment: .leading)
                }
                .buttonStyle(CoachWorldActionButtonStyle(
                    role: choice.isAvailable ? .live : .secondary, palette: palette
                ))
                .disabled(!choice.isAvailable)
                .accessibilityLabel("\(choice.title) for \(prospect.person.name)")
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
}
