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
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header
                    if let statusMessage {
                        Text(statusMessage)
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
            Text("PROSPECT PROFILE")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("Stable-ID dossier · \(model.prospects.count + model.discovery.count) visible prospects")
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func dossier(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
            HStack(alignment: .top, spacing: CoachWorldTokens.Space.sm) {
                CoachWorldBlankPhotoPlate(
                    name: prospect.person.name,
                    palette: palette,
                    width: 56,
                    height: 64
                )
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(prospect.person.name)
                        .font(CoachWorldTokens.TypeRole.title.weight(.black))
                    Text(prospect.boardRank == 0
                         ? "Discovery · \(prospect.position)"
                         : "Board #\(prospect.boardRank) · \(prospect.position)")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.collegeIdentity.color)
                    Text("\(prospect.hometown) · \(prospect.status)")
                        .foregroundStyle(palette.contentSecondary.color)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(prospect.person.name), \(prospect.position), \(prospect.hometown), \(prospect.status)"
            )

            section("SYSTEM EVALUATION") {
                Text(prospect.evaluation.verdict)
                    .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: CoachWorldTokens.Space.md) {
                    metric("SCHEME FIT", prospect.evaluation.schemeFit)
                    metric("UNCERTAINTY", prospect.evaluation.uncertainty)
                }
                if !prospect.evaluation.citedOutliers.isEmpty {
                    Text(prospect.evaluation.citedOutliers.prefix(3).joined(separator: " · "))
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            section("RELATIONSHIP HISTORY") {
                if prospect.relationshipHistory.isEmpty {
                    Text("No contact recorded.")
                        .foregroundStyle(palette.contentSecondary.color)
                } else {
                    ForEach(prospect.relationshipHistory, id: \.stableID) { event in
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            Text("\(event.dateLabel) · \(event.summary)")
                                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                            Text(event.effect)
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentSecondary.color)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            section("LEGAL ACTIONS") {
                if prospect.choices.isEmpty {
                    Text("No action is currently available.")
                        .foregroundStyle(palette.contentSecondary.color)
                } else {
                    ForEach(prospect.choices, id: \.intentID) { choice in
                        Button {
                            onAction(prospect.stableID, choice.intentID)
                        } label: {
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                Text(choice.title).font(CoachWorldTokens.TypeRole.body.weight(.black))
                                Text(choice.isAvailable
                                     ? "\(choice.cost) · \(choice.consequence)"
                                     : (choice.unavailableReason ?? "Unavailable"))
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                                   alignment: .leading)
                        }
                        .buttonStyle(CoachWorldActionButtonStyle(
                            role: choice.isAvailable ? .live : .secondary,
                            palette: palette
                        ))
                        .disabled(!choice.isAvailable)
                        .accessibilityLabel("\(choice.title) for \(prospect.person.name)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            content()
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
        )
        .accessibilityElement(children: .contain)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title).font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            Text(value).font(CoachWorldTokens.TypeRole.body.weight(.black))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
